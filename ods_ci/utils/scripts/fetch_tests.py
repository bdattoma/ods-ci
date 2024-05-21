import argparse
import os

from robot.model import SuiteVisitor
from robot.running import TestSuiteBuilder
import sys
from util import execute_command


class TestCasesFinder(SuiteVisitor):
    def __init__(self):
        self.tests = []

    def visit_test(self, test):
        self.tests.append(test)

class Extractor:
    def __init__(self, test_repo, ref_1, ref_2, ref_2_auto, output_argument_file) -> None:
        self.test_repo = test_repo
        self.repo_local_path = "./ods_ci/ods-ci-temp"
        self.ref_1 = ref_1
        self.ref_2 = ref_2_auto
        self.output_argument_file = output_argument_file


    def get_repository(self):
        """
        If $test_repo is a remote repo, the function clones it in "ods-ci-temp" directory.
        If $test_repo is a local path, the function checks the path exists.
        """
        # repo_local_path = "./ods_ci/ods-ci-temp"
        if "http" in self.test_repo or "git@" in self.test_repo:
            print("Cloning repo ", self.test_repo)
            ret = execute_command(f"git clone {self.test_repo} {self.repo_local_path}")
            if "error" in ret.lower():
                # actual error gets printed during "execute_command"
                raise Exception("Failed to clone the given repository")
        elif not os.path.exists(self.test_repo):
            raise FileNotFoundError(f"local path {self.test_repo} was not found")
        else:
            print("Using local repo ", self.test_repo)
            repo_local_path = self.test_repo


    def checkout_repository(self, ref):
        """
        Checkouts the repository at current directory to the given branch/commit ($ref)
        """
        ret = execute_command(f"git checkout {ref}")
        if "error" in ret.lower():
            # actual error gets printed during "execute_command"
            raise Exception(f"Failed to checkout to the given branch/commit {ref}")
        ret = execute_command("git checkout")


    def extract_test_cases_from_ref(self, repo_local_path, ref):
        """
        Navigate to the $test_repo directory, checkouts the target branch/commit ($ref) and extracts
        the test case titles leveraging RobotFramework TestSuiteBuilder() and TestCasesFinder() classes
        """
        curr_dir = os.getcwd()
        try:
            os.chdir(repo_local_path)
            self.checkout_repository(ref)
            builder = TestSuiteBuilder()
            testsuite = builder.build("ods_ci/tests/")
            finder = TestCasesFinder()
            tests = []
            testsuite.visit(finder)
            for test in finder.tests:
                # print (f'"{test.tags}"') # for future reference in order to fetch test tags
                tests.append(test.name)
        except Exception as err:
            print(err)
            os.chdir(curr_dir)
            raise
        os.chdir(curr_dir)
        return tests

    def extract_test_cases(self):
        """
        Returns the tests extracted from each reference, and auto-select the second branch (ref_2)
        if --ref2-auto argument is set to True
        """
        print(f"\n---| Extracting test cases from {self.ref_1} branch/commit |---")
        self.tests_1 = self.extract_test_cases_from_ref(self.repo_local_path, self.ref_1)
        print(f"\nDone. Found {len(self.tests_1)} test cases")
        if self.ref_2_auto:
            print("\n---| Auto-selecting ref_2 branch")
            ret = execute_command(f"git branch -a --sort=committerdate | grep -v \"({self.ref_1}|master|main)$\" | grep releases/ | tail -1")
            if ret != "":
                print(f"Done. {ret} branch selected as ref_2")
                self.ref_2 = ret
            else:
                print(f"Something went wrong while auto-selecting ref_2 branch.")
                sys.exit(1)
        print(f"\n---| Extracting test cases from {self.ref_2} branch/commit |---")
        self.tests_2 = self.extract_test_cases_from_ref(self.repo_local_path, self.ref_2)
        print(f"Done. Found {len(self.tests_2)} test cases")


    def generate_rf_argument_file(tests, output_filepath):
        """
        Writes the RobotFramework argument file containing the test selection args
        to include the extracted new tests in previous stage of this script.
        """
        content = ""
        for testname in tests:
            content += f"--test {testname.strip()}\n"
        try:
            with open(output_filepath, "w") as argfile:
                argfile.write(content)
        except Exception as err:
            print("Failed to generate argument file")
            print(err)


    def extract_new_test_cases(test_repo, ref_1, ref_2, ref_2_auto, output_argument_file):
        """
        Wrapping function for all the new tests extraction stages.
        """
        repo_local_path = get_repository(test_repo)
        tests_1, tests_2 = extract_test_cases(repo_local_path, ref_1, ref_2, ref_2_auto)
        print("\n---| Computing differences |----")
        new_tests = list(set(tests_1) - set(tests_2))
        if len(new_tests) == 0:
            print(f"[WARN] Done. No new tests found in {ref_1} with respect to {ref_2}!")
            print("Skip argument file creation")
        else:
            print(f"Done. Found {len(new_tests)} new tests in {ref_1} which were not present in {ref_2}")
            if output_argument_file is not None:
                print("\n---| Generating RobotFramework arguments file |----")
                generate_rf_argument_file(new_tests, output_argument_file)
                print("Done.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        usage=argparse.SUPPRESS,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Script to fetch newly added test cases",
    )

    parser.add_argument(
        "-A",
        "--output-argument-file",
        help="generate argument file for RobotFramework to include test cases. It expects to receive a file path",
        action="store",
        dest="output_argument_file",
        default=None,
    )
    parser.add_argument(
        "--test-repo",
        help="ODS-CI repository. It accepts either local path or URL",
        action="store",
        dest="test_repo",
        default="https://github.com/red-hat-data-services/ods-ci",
    )
    parser.add_argument(
        "--ref1",
        help="first branch or commit to use for comparison (e.g., newer one)",
        action="store",
        dest="ref_1",
        default="master",
    )
    parser.add_argument(
        "--ref2",
        help="second branch or commit to use for comparison (e.g., older one)",
        action="store",
        dest="ref_2",
        default="releases/2.8.0",
    )
    parser.add_argument(
        "--ref2-auto",
        help="auto-selects latest updated branch to use for comparison. It excludes --ref1 and 'master' from selection",
        action="store",
        dest="ref_2_auto",
        default=False,
    )

    args = parser.parse_args()

    extract_new_test_cases(
        args.test_repo,
        args.ref_1,
        args.ref_2,
        args.ref_2_auto,
        args.output_argument_file,
    )

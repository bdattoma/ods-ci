*** Settings ***
Documentation       Test suite for OpenShift Pipeline API
Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Common.robot
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource            ../../../Resources/Page/Operators/OpenShiftPipelines.resource
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDataSciencePipelines.resource
Library             DateTime
Library             ../../../../libs/DataSciencePipelinesAPI.py
Suite Setup         Data Science Pipelines Suite Setup
Suite Teardown      RHOSi Teardown


*** Variables ***
${URL_TEST_PIPELINE_RUN_YAML}=                 https://raw.githubusercontent.com/opendatahub-io/data-science-pipelines-operator/main/tests/resources/dsp-operator/test-pipeline-run.yaml


*** Test Cases ***
Verify Ods Users Can Create And Run a Data Science Pipeline Using The Api
    [Documentation]    Creates, runs pipelines with admin and regular user. Double check the pipeline result and clean
    ...    the pipeline resources.
    [Tags]      Sanity
    ...         Tier1
    ...         ODS-2083
    End To End Pipeline Workflow Via Api    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}    pipelinesapi1
    End To End Pipeline Workflow Via Api    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    pipelinesapi2


*** Keywords ***
End To End Pipeline Workflow Via Api
    [Documentation]    Create, run and double check the pipeline result using API. In the end, clean the pipeline resources.    # robocop: disable:line-too-long
    [Arguments]     ${username}    ${password}    ${project}
    Remove Pipeline Project    ${project}
    New Project    ${project}
    Install DataSciencePipelinesApplication CR    ${project}
    ${status}    Login And Wait Dsp Route    ${username}    ${password}    ${project}    ds-pipeline-ui-sample
    Should Be True    ${status} == 200    Could not login to the Data Science Pipelines Rest API OR DSP routing is not working    # robocop: disable:line-too-long
    ${pipeline_id}    Create Pipeline    ${URL_TEST_PIPELINE_RUN_YAML}
    ${run_id}    Create Run    ${pipeline_id}
    ${run_status}    Check Run Status    ${run_id}
    Should Be True    '${run_status}' == 'Completed'    Pipeline run doesn't have Completed status
    Delete Runs    ${run_id}
    Delete Pipeline    ${pipeline_id}
    [Teardown]    Remove Pipeline Project    ${project}

Data Science Pipelines Suite Setup
    [Documentation]    Data Science Pipelines Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Install Red Hat OpenShift Pipelines
*** Settings ***
Documentation     Collection of CLI tests to validate the model serving stack for Large Language Models (LLM)
...               using different runtimes other than Caikit+TGIS combined, e.g., TGIS Standalone, Caikit standalone
Resource          ../../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../../Resources/OCP.resource
Resource          ../../../../Resources/Page/Operators/ISVs.resource
Resource          ../../../../Resources/CLI/ModelServing/llm.resource
Library            OpenShiftLibrary
Suite Setup       Suite Setup
# Suite Teardown    RHOSi Teardown
Test Tags         KServe


*** Variables ***
${TEST_NS_TGIS}=    singlemodel-tgis
${FLAN_MODEL_S3_DIR}=    flan-t5-small/flan-t5-small-hf
${FLAN_STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${FLAN_MODEL_S3_DIR}/
${TGIS_RUNTIME_NAME}=    tgis-runtime


*** Test Cases ***
Verify User Can Serve And Query A Model With TGIS-Standalone Runtime
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve and TGIS standalone runtime
    [Tags]    Sanity    Tier1    ODS-XYZ
    [Setup]    Run Keywords    Set Project And Runtime    namespace=${TEST_NS_TGIS}    runtime=${TGIS_RUNTIME_NAME}
    ...        AND
    ...        Run    git clone https://github.com/IBM/text-generation-inference/
    ${test_namespace}=    Set Variable     ${TEST_NS_TGIS}
    ${model_name}=    Set Variable    flan-t5-small-hf
    ${models_names}=    Create List    ${model_name}
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_name}    runtime=tgis-runtime
    ...    endpoint=${TGIS_ALLTOKENS_ENDPOINT}    n_times=1
    ...    namespace=${test_namespace}
    # temp disabled
    # Query Model Multiple Times    model_name=${model_name}
    # ...    endpoint=${CAIKIT_STREAM_ENDPOINT}    n_times=1    streamed_response=${TRUE}
    # ...    namespace=${test_namespace}
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}


*** Keywords ***
Suite Setup
    [Documentation]
    Skip If Component Is Not Enabled    kserve
    # RHOSi Setup
    Load Expected Responses
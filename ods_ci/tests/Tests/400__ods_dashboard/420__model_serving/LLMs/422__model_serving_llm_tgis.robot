*** Settings ***
Documentation     Collection of CLI tests to validate the model serving stack for Large Language Models (LLM).
...               These tests leverage on TGIS Standalone Serving Runtime
Resource          ../../../../Resources/OCP.resource
Resource          ../../../../Resources/CLI/ModelServing/llm.resource
Library            OpenShiftLibrary
Suite Setup       Suite Setup
Suite Teardown    RHOSi Teardown
Test Tags         KServe


*** Variables ***
${FLAN_MODEL_S3_DIR}=    flan-t5-small/flan-t5-small-hf
${FLAN_GRAMMAR_MODEL_S3_DIR}=    flan-t5-large-grammar-synthesis-caikit/flan-t5-large-grammar-synthesis-caikit
${FLAN_LARGE_MODEL_S3_DIR}=    flan-t5-large/flan-t5-large
${BLOOM_MODEL_S3_DIR}=    bloom-560m/bloom-560m-caikit
${FLAN_STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${FLAN_MODEL_S3_DIR}
${FLAN_GRAMMAR_STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${FLAN_GRAMMAR_MODEL_S3_DIR}/artifacts
${FLAN_LARGE_STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${FLAN_LARGE_MODEL_S3_DIR}/artifacts
${BLOOM_STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${BLOOM_MODEL_S3_DIR}/artifacts
${TEST_NS}=    tgis-standalone
${TGIS_RUNTIME_NAME}=    tgis-runtime
@{SEARCH_METRICS}=    tgi_    istio_

 
*** Test Cases ***
Verify User Can Serve And Query A Model
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve and Caikit+TGIS runtime
    [Tags]    Tier1    ODS-2341
    [Setup]    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=${TEST_NS}-cli
    ${test_namespace}=    Set Variable     ${TEST_NS}-cli
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=tokenize    n_times=1
    ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=model-info    n_times=1
    ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    validate_response=${FALSE}
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Deploy Multiple Models In The Same Namespace
    [Documentation]    Checks if user can deploy and query multiple models in the same namespace
    [Tags]    Tier1    ODS-2371
    [Setup]    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=${TEST_NS}-multisame
    ${test_namespace}=    Set Variable     ${TEST_NS}-multisame
    ${model_one_name}=    Set Variable    bloom-560m-caikit
    ${model_two_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${model_one_name}    ${model_two_name}
    Compile Inference Service YAML    isvc_name=${model_one_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${BLOOM_STORAGE_URI}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Compile Inference Service YAML    isvc_name=${model_two_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_one_name}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_two_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_one_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    n_times=5    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_two_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    n_times=10    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_one_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    n_times=5    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_two_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    n_times=10    namespace=${test_namespace}
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Deploy Multiple Models In Different Namespaces
    [Documentation]    Checks if user can deploy and query multiple models in the different namespaces
    [Tags]    Tier1    ODS-2378
    [Setup]    Run Keywords    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=singlemodel-multi1
    ...        AND
    ...        Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=singlemodel-multi2
    ${model_one_name}=    Set Variable    bloom-560m-caikit
    ${model_two_name}=    Set Variable    flan-t5-small-caikit
    ${models_names_ns_1}=    Create List    ${model_one_name}
    ${models_names_ns_2}=    Create List    ${model_two_name}
    Compile Inference Service YAML    isvc_name=${model_one_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${BLOOM_STORAGE_URI}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=singlemodel-multi1
    Compile Inference Service YAML    isvc_name=${model_two_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=singlemodel-multi2
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_one_name}
    ...    namespace=singlemodel-multi1
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_two_name}
    ...    namespace=singlemodel-multi2
    Query Model Multiple Times    model_name=${model_one_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    n_times=2    namespace=singlemodel-multi1
    Query Model Multiple Times    model_name=${model_two_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    n_times=2    namespace=singlemodel-multi2
    [Teardown]    Run Keywords    Clean Up Test Project    test_ns=singlemodel-multi1    isvc_names=${models_names_ns_1}
    ...           wait_prj_deletion=${FALSE}
    ...           AND
    ...           Clean Up Test Project    test_ns=singlemodel-multi2    isvc_names=${models_names_ns_2}
    ...           wait_prj_deletion=${FALSE}

Verify Model Upgrade Using Canaray Rollout
    [Documentation]    Checks if user can apply Canary Rollout as deployment strategy
    [Tags]    Tier1    ODS-2372
    [Setup]    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=canary-model-upgrade
    ${test_namespace}=    Set Variable    canary-model-upgrade
    ${isvc_name}=    Set Variable    canary-caikit
    ${model_name}=    Set Variable    flan-t5-small-caikit
    ${isvcs_names}=    Create List    ${isvc_name}
    ${canary_percentage}=    Set Variable    ${30}
    Compile Deploy And Query LLM model   isvc_name=${isvc_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_name=${model_name}
    ...    namespace=${test_namespace}
    ...    validate_response=${FALSE}
    ...    model_format=pytorch    runtime=${TGIS_RUNTIME_NAME}
    Log To Console    Applying Canary Tarffic for Model Upgrade
    ${model_name}=    Set Variable    bloom-560m-caikit
    Compile Deploy And Query LLM model   isvc_name=${isvc_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${BLOOM_STORAGE_URI}
    ...    model_name=${model_name}
    ...    canaryTrafficPercent=${canary_percentage}
    ...    namespace=${test_namespace}
    ...    validate_response=${FALSE}
    ...    n_queries=${0}
    ...    model_format=pytorch    runtime=${TGIS_RUNTIME_NAME}
    Traffic Should Be Redirected Based On Canary Percentage    exp_percentage=${canary_percentage}
    ...    isvc_name=${isvc_name}    model_name=${model_name}    namespace=${test_namespace}
    ...    runtime=${TGIS_RUNTIME_NAME}
    Log To Console    Remove Canary Tarffic For Model Upgrade
    Compile Deploy And Query LLM model    isvc_name=${isvc_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_name=${model_name}
    ...    model_storage_uri=${BLOOM_STORAGE_URI}
    ...    namespace=${test_namespace}
    ...    model_format=pytorch    runtime=${TGIS_RUNTIME_NAME}
    Traffic Should Be Redirected Based On Canary Percentage    exp_percentage=${100}
    ...    isvc_name=${isvc_name}    model_name=${model_name}    namespace=${test_namespace}
    ...    runtime=${TGIS_RUNTIME_NAME}
    [Teardown]   Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${isvcs_names}    wait_prj_deletion=${FALSE}

Verify Model Pods Are Deleted When No Inference Service Is Present
    [Documentation]    Checks if model pods gets successfully deleted after
    ...                deleting the KServe InferenceService object
    [Tags]    Tier2    ODS-2373
    [Setup]    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=no-infer-kserve
    ${flan_isvc_name}=    Set Variable    flan-t5-small-caikit
    ${model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${model_name}
    Compile Deploy And Query LLM model   isvc_name=${flan_isvc_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_name=${model_name}
    ...    namespace=no-infer-kserve
    ...    model_format=pytorch    runtime=${TGIS_RUNTIME_NAME}
    Delete InfereceService    isvc_name=${flan_isvc_name}    namespace=no-infer-kserve
    ${rc}    ${out}=    Run And Return Rc And Output    oc wait pod -l serving.kserve.io/inferenceservice=${flan_isvc_name} -n no-infer-kserve --for=delete --timeout=200s
    Should Be Equal As Integers    ${rc}    ${0}
    [Teardown]   Clean Up Test Project    test_ns=no-infer-kserve
    ...    isvc_names=${models_names}   isvc_delete=${FALSE}
    ...    wait_prj_deletion=${FALSE}

Verify User Can Change The Minimum Number Of Replicas For A Model
    [Documentation]    Checks if user can change the minimum number of replicas
    ...                of a deployed model.
    ...                Affected by:  https://issues.redhat.com/browse/SRVKS-1175
    [Tags]    Tier1    ODS-2376
    [Setup]    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=${TEST_NS}-reps
    ${test_namespace}=    Set Variable     ${TEST_NS}-reps
    ${model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${model_name}
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    min_replicas=1
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    exp_replicas=1
    Query Model Multiple Times    model_name=${model_name}    runtime=${TGIS_RUNTIME_NAME}    n_times=3
    ...    namespace=${test_namespace}
    ${rev_id}=    Set Minimum Replicas Number    n_replicas=3    model_name=${model_name}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Terminated    label_selector=serving.knative.dev/revisionUID=${rev_id}
    ...    namespace=${test_namespace}    timeout=360s
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    exp_replicas=3
    Query Model Multiple Times    model_name=${model_name}    runtime=${TGIS_RUNTIME_NAME}    n_times=3
    ...    namespace=${test_namespace}
    ${rev_id}=    Set Minimum Replicas Number    n_replicas=1    model_name=${model_name}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Terminated    label_selector=serving.knative.dev/revisionUID=${rev_id}
    ...    namespace=${test_namespace}    timeout=360s
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    exp_replicas=1
    Query Model Multiple Times    model_name=${model_name}    runtime=${TGIS_RUNTIME_NAME}    n_times=3
    ...    namespace=${test_namespace}
    [Teardown]   Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Autoscale Using Concurrency
    [Documentation]    Checks if model successfully scale up based on concurrency metrics (KPA)
    [Tags]    Tier1    ODS-2377
    [Setup]    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=autoscale-con
    ${test_namespace}=    Set Variable    autoscale-con
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    auto_scale=True
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}    n_times=10
    ...    namespace=${test_namespace}    validate_response=${FALSE}    background=${TRUE}
    Wait For Pods Number    number=1    comparison=GREATER THAN
    ...    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    [Teardown]   Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Validate Scale To Zero
    [Documentation]    Checks if model successfully scale down to 0 if there's no traffic
    [Tags]    Tier1    ODS-2379    AutomationBug
    [Setup]    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=autoscale-zero
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=autoscale-zero
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=autoscale-zero
    ${host}=    Get KServe Inference Host Via CLI    isvc_name=${flan_model_name}   namespace=autoscale-zero
    ${body}=    Set Variable    '{"text": "At what temperature does liquid Nitrogen boil?"}'
    ${header}=    Set Variable    'mm-model-id: ${flan_model_name}'
    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint="caikit.runtime.Nlp.NlpService/TextGenerationTaskPredict"
    ...    json_body=${body}    json_header=${header}
    ...    insecure=${TRUE}
    Set Minimum Replicas Number    n_replicas=0    model_name=${flan_model_name}
    ...    namespace=autoscale-zero
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=autoscale-zero
    Wait For Pods To Be Terminated    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=autoscale-zero
    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint="caikit.runtime.Nlp.NlpService/TextGenerationTaskPredict"
    ...    json_body=${body}    json_header=${header}
    ...    insecure=${TRUE}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=autoscale-zero
    Wait For Pods To Be Terminated    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=autoscale-zero
    [Teardown]   Clean Up Test Project    test_ns=autoscale-zero
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Set Requests And Limits For A Model
    [Documentation]    Checks if user can set HW request and limits on their inference service object
    [Tags]    Tier1    ODS-2380
    [Setup]    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=hw-res
    ${test_namespace}=    Set Variable    hw-res
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    ${requests}=    Create Dictionary    cpu=1    memory=2Gi
    ${limits}=    Create Dictionary    cpu=2    memory=4Gi
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    requests_dict=${requests}    limits_dict=${limits}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    ${rev_id}=    Get Current Revision ID    model_name=${flan_model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}    n_times=1
    ...    namespace=${test_namespace}
    Container Hardware Resources Should Match Expected    container_name=kserve-container
    ...    pod_label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    exp_requests=${requests}    exp_limits=${limits}
    ${new_requests}=    Create Dictionary    cpu=2    memory=3Gi
    Set Model Hardware Resources    model_name=${flan_model_name}    namespace=hw-res
    ...    requests=${new_requests}    limits=${NONE}
    Wait For Pods To Be Terminated    label_selector=serving.knative.dev/revisionUID=${rev_id}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    exp_replicas=1
    Container Hardware Resources Should Match Expected    container_name=kserve-container
    ...    pod_label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    exp_requests=${new_requests}    exp_limits=${NONE}
    [Teardown]   Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify Model Can Be Served And Query On A GPU Node
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model on GPU node
    ...                using Kserve and Caikit+TGIS runtime
    [Tags]    Tier1    ODS-2381    Resources-GPU
    [Setup]    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=singlemodel-gpu
    ${test_namespace}=    Set Variable    singlemodel-gpu
    ${model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${model_name}
    ${requests}=    Create Dictionary    nvidia.com/gpu=1
    ${limits}=    Create Dictionary    nvidia.com/gpu=1
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    requests_dict=${requests}    limits_dict=${limits}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}
    Container Hardware Resources Should Match Expected    container_name=kserve-container
    ...    pod_label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    exp_requests=${requests}    exp_limits=${limits}
    Model Pod Should Be Scheduled On A GPU Node    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_name}    runtime=${TGIS_RUNTIME_NAME}    n_times=10
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_name}    runtime=${TGIS_RUNTIME_NAME}    n_times=5
    ...    namespace=${test_namespace}    inference_type=streaming    validate_response=${FALSE}
    [Teardown]   Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${model_name}    wait_prj_deletion=${FALSE}

Verify Non Admin Can Serve And Query A Model
    [Documentation]    Basic tests leveraging on a non-admin user for preparing, deploying and querying a LLM model
    ...                using Kserve and Caikit+TGIS runtime
    [Tags]    Tier1    ODS-2326
    [Setup]    Run Keywords   Login To OCP Using API    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}  AND
    ...        Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=non-admin-test
    ${test_namespace}=    Set Variable     non-admin-test
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    ${host}=    Get KServe Inference Host Via CLI    isvc_name=${flan_model_name}   namespace=${test_namespace}
    ${body}=    Set Variable    '{"text": "${EXP_RESPONSES}[queries][0][query_text]"}'
    ${header}=    Set Variable    'mm-model-id: ${flan_model_name}'
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1    validate_response=${FALSE}
    ...    namespace=${test_namespace}
    [Teardown]  Run Keywords   Login To OCP Using API    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}   AND
    ...        Clean Up Test Project    test_ns=${test_namespace}   isvc_names=${models_names}
    ...        wait_prj_deletion=${FALSE}

Verify User Can Serve And Query Flan-t5 Grammar Syntax Corrector
    [Documentation]    Deploys and queries flan-t5-large-grammar-synthesis model
    [Tags]    Tier2    ODS-2441
    [Setup]    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=grammar-model
    ${test_namespace}=    Set Variable     grammar-model
    ${flan_model_name}=    Set Variable    flan-t5-large-grammar-synthesis-caikit
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_GRAMMAR_STORAGE_URI}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}    query_idx=1
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1    validate_response=${FALSE}
    ...    namespace=${test_namespace}    query_idx=${1}
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Serve And Query Flan-t5 Large
    [Documentation]    Deploys and queries flan-t5-large model
    [Tags]    Tier2    ODS-2434
    [Setup]    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=flan-t5-large3
    ${test_namespace}=    Set Variable     flan-t5-large3
    ${flan_model_name}=    Set Variable    flan-t5-large
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_LARGE_STORAGE_URI}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}    query_idx=${0}
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1    validate_response=${FALSE}
    ...    namespace=${test_namespace}    query_idx=${0}
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify Runtime Upgrade Does Not Affect Deployed Models
    [Documentation]    Upgrades the caikit runtime inthe same NS where a model
    ...                is already deployed. The expecation is that the current model
    ...                must remain unchanged after the runtime upgrade.
    ...                ATTENTION: this is an approximation of the runtime upgrade scenario, however
    ...                the real case scenario will be defined once RHODS actually ships the Caikit runtime.
    [Tags]    Tier1    ODS-2404
    [Setup]    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=${TEST_NS}-up
    ${test_namespace}=    Set Variable     ${TEST_NS}-up
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}
    ${created_at}    ${caikitsha}=    Get Model Pods Creation Date And Image URL    model_name=${flan_model_name}
    ...    namespace=${test_namespace}    container=kserve-container
    Upgrade Runtime Image    container=kserve-container    runtime=${TGIS_RUNTIME_NAME}
    ...    new_image_url=quay.io/modh/text-generation-inference:fast
    ...    namespace=${test_namespace}
    Sleep    5s    reason=Sleep, in case the runtime upgrade takes some time to start performing actions on the pods...
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    exp_replicas=1
    ${created_at_after}    ${caikitsha_after}=    Get Model Pods Creation Date And Image URL    model_name=${flan_model_name}
    ...    namespace=${test_namespace}    container=kserve-container
    Should Be Equal    ${created_at}    ${created_at_after}
    Should Be Equal As Strings    ${caikitsha}    ${caikitsha_after}
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Access Model Metrics From UWM
    [Documentation]    Verifies that model metrics are available for users in the
    ...                OpenShift monitoring system (UserWorkloadMonitoring)
    ...                PARTIALLY DONE: it is checking number of requests, number of successful requests
    ...                and model pod cpu usage. Waiting for a complete list of expected metrics and
    ...                derived metrics.
    [Tags]    Tier1    ODS-2401
    [Setup]    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=singlemodel-metrics    enable_metrics=${TRUE}
    ${test_namespace}=    Set Variable     singlemodel-metrics
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    ${thanos_url}=    Get OpenShift Thanos URL
    ${token}=    Generate Thanos Token
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    
    Wait Until Keyword Succeeds    30 times    4s
    ...    Metrics Should Exist In UserWorkloadMonitoring
    ...    thanos_url=${thanos_url}    thanos_token=${token}
    ...    search_metrics=${SEARCH_METRICS}
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=3
    ...    namespace=${test_namespace}
    Wait Until Keyword Succeeds    50 times    5s
    ...    User Can Fetch Number Of Requests Over Defined Time    thanos_url=${thanos_url}    thanos_token=${token}
    ...    model_name=${flan_model_name}    query_kind=single    namespace=${test_namespace}    period=5m    exp_value=3
    Wait Until Keyword Succeeds    20 times    5s
    ...    User Can Fetch Number Of Successful Requests Over Defined Time    thanos_url=${thanos_url}    thanos_token=${token}
    ...    model_name=${flan_model_name}    namespace=${test_namespace}    period=5m    exp_value=3
    Wait Until Keyword Succeeds    20 times    5s
    ...    User Can Fetch CPU Utilization    thanos_url=${thanos_url}    thanos_token=${token}
    ...    model_name=${flan_model_name}    namespace=${test_namespace}    period=5m
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1    validate_response=${FALSE}
    ...    namespace=${test_namespace}    query_idx=${0}
    Wait Until Keyword Succeeds    30 times    5s
    ...    User Can Fetch Number Of Requests Over Defined Time    thanos_url=${thanos_url}    thanos_token=${token}
    ...    model_name=${flan_model_name}    query_kind=stream    namespace=${test_namespace}    period=5m    exp_value=1
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Query A Model Using HTTP Calls
    [Documentation]    From RHOAI 2.5 HTTP is allowed and default querying protocol.
    ...                This tests deploys the runtime enabling HTTP port and send queries to the model
    [Tags]    ODS-2501    Tier1    ProductBug
    [Setup]    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=kserve-http    protocol=http
    ${test_namespace}=    Set Variable     kserve-http
    ${model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${model_name}
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_name}    runtime=${TGIS_RUNTIME_NAME}    protocol=http
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}    query_idx=${0}
    # temporarily disabling stream response validation. Need to re-design the expected response json file
    # because format of streamed response with http is slightly different from grpc
    Query Model Multiple Times    model_name=${model_name}    runtime=${TGIS_RUNTIME_NAME}    protocol=http
    ...    inference_type=streaming    n_times=1    validate_response=${FALSE}
    ...    namespace=${test_namespace}    query_idx=${0}    validate_response=${FALSE}
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}


*** Keywords ***
Suite Setup
    [Documentation]
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Load Expected Responses
    Run    git clone https://github.com/IBM/text-generation-inference/
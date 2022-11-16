*** Settings ***
Library            SeleniumLibrary
Library            OpenShiftLibrary
Resource           ../../../Resources/OCP.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Workbenches.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Storages.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Suite Setup        Project Suite Setup
Suite Teardown     Project Suite Teardown
Test Setup         Launch Data Science Project Main Page
Test Teardown      Close All Browsers


*** Variables ***
${PRJ_TITLE}=   ODS-CI DS Project
${PRJ_RESOURCE_NAME}=   ods-ci-ds-project-test
${PRJ_DESCRIPTION}=   ODS-CI DS Project is a test for validating DSG feature
${NB_IMAGE}=        Minimal Python
${WORKBENCH_TITLE}=   ODS-CI Workbench 1
${WORKBENCH_DESCRIPTION}=   ODS-CI Workbench 1 is a test workbench using ${NB_IMAGE} image to test DS Projects feature
${WORKBENCH_2_TITLE}=   ODS-CI Workbench 2
${WORKBENCH_2_DESCRIPTION}=   ODS-CI Workbench 2 is a test workbench using ${NB_IMAGE} image to test DS Projects feature
${WORKBENCH_3_TITLE}=   ODS-CI Workbench 3
${WORKBENCH_3_DESCRIPTION}=   ODS-CI Workbench 3 is a test workbench using ${NB_IMAGE} image to test DS Projects feature
${PV_BASENAME}=         ods-ci-pv
${PV_DESCRIPTION}=         ods-ci-pv is a PV created to test DS Projects feature
# PV size are in GB
${PV_SIZE}=         2
${DC_S3_NAME}=    ods-ci-s3
${DC_S3_ENDPOINT}=    custom.endpoint.s3.com
${DC_S3_REGION}=    ods-ci-region
${DC_S3_TYPE}=    Object storage


*** Test Cases ***
Verify User Cannot Create Project With Empty Fields
    [Tags]    ODS-1783
    Create Project With Empty Title And Expect Error
    # add close modal

Verify User Cannot Create Project Using Special Chars In Resource Name
    [Tags]    ODS-1783
    Create Project With Special Chars In Resource Name And Expect Error
    # add close modal

Verify User Can Access Only Its Owned Projects
    [Tags]    ODS-1868
    [Setup]    Set Variables For User Access Test
    Launch Data Science Project Main Page    username=${TEST_USER_3.USERNAME}    password=${TEST_USER_3.PASSWORD}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_1_USER3}    description=${EMPTY}
    Open Data Science Projects Home Page
    Project Should Be Listed    project_title=${PRJ_1_USER3}
    Project's Owner Should Be   expected_username=${TEST_USER_3.USERNAME}   project_title=${PRJ_1_USER3}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_2_USER3}    description=${EMPTY}
    Open Data Science Projects Home Page
    Project Should Be Listed    project_title=${PRJ_2_USER3}
    Project's Owner Should Be   expected_username=${TEST_USER_3.USERNAME}   project_title=${PRJ_2_USER3}
    Launch Data Science Project Main Page    username=${TEST_USER_4.USERNAME}    password=${TEST_USER_4.PASSWORD}
    Create Data Science Project    title=${PRJ_A_USER4}    description=${EMPTY}
    Open Data Science Projects Home Page
    Number Of Displayed Projects Should Be    expected_number=1
    Project Should Be Listed    project_title=${PRJ_A_USER4}
    Project's Owner Should Be   expected_username=${TEST_USER_4.USERNAME}   project_title=${PRJ_A_USER4}
    Project Should Not Be Listed    project_title=${PRJ_1_USER3}
    Project Should Not Be Listed    project_title=${PRJ_2_USER3}
    Switch Browser    1
    Number Of Displayed Projects Should Be    expected_number=2
    Project Should Not Be Listed    project_title=${PRJ_A_USER4}
    Project Should Be Listed    project_title=${PRJ_1_USER3}
    Project Should Be Listed    project_title=${PRJ_2_USER3}
    Launch Data Science Project Main Page    username=${TEST_USER.USERNAME}    password=${TEST_USER.PASSWORD}
    Capture Page Screenshot
    Number Of Displayed Projects Should Be    expected_number=3
    Project Should Be Listed    project_title=${PRJ_1_USER3}
    Project Should Be Listed    project_title=${PRJ_2_USER3}
    Project Should Be Listed    project_title=${PRJ_A_USER4}
    Launch Data Science Project Main Page    username=${OCP_ADMIN_USER.USERNAME}    password=${OCP_ADMIN_USER.PASSWORD}    ocp_user_auth_type=${OCP_ADMIN_USER.AUTH_TYPE}
    Capture Page Screenshot
    Number Of Displayed Projects Should Be    expected_number=3
    Project Should Be Listed    project_title=${PRJ_1_USER3}
    Project Should Be Listed    project_title=${PRJ_2_USER3}
    Project Should Be Listed    project_title=${PRJ_A_USER4}

Verify User Can Create A Data Science Project
    [Tags]    ODS-1775
    [Setup]   Launch Data Science Project Main Page
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}    resource_name=${PRJ_RESOURCE_NAME}
    Open Data Science Projects Home Page
    Project Should Be Listed    project_title=${PRJ_TITLE}
    Project's Owner Should Be   expected_username=${TEST_USER_3.USERNAME}   project_title=${PRJ_TITLE}
    ${ns_name}=    Check Corresponding Namespace Exists    project_title=${PRJ_TITLE}

Verify User Can Create And Start A Workbench With Ephimeral Storage
    [Tags]    ODS-1812
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${EMPTY}  workbench_description=${EMPTY}  prj_title=${PRJ_TITLE}
    ...                 image_name=${NB_IMAGE}   deployment_size=Small  storage=Ephemeral  pv_existent=${NONE}
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}  press_cancel=${TRUE}
    Create Workbench    workbench_title=${WORKBENCH_TITLE}  workbench_description=${WORKBENCH_DESCRIPTION}  prj_title=${PRJ_TITLE}
    ...                 image_name=${NB_IMAGE}   deployment_size=Small  storage=Ephemeral  pv_existent=${NONE}
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}
    Workbench Should Be Listed      workbench_title=${WORKBENCH_TITLE}
    Workbench Status Should Be      workbench_title=${WORKBENCH_TITLE}      status=${WORKBENCH_STATUS_STARTING}
    # the continue on failure should be temporary
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE}
    Check Corresponding Notebook CR Exists      workbench_title=${WORKBENCH_TITLE}   namespace=${ns_name}

Verify User Can Create A PV Storage
    [Tags]    ODS-1819
    ${pv_name}=    Set Variable    ${PV_BASENAME}-A
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    ${workbenchs}=    Create Dictionary    ${WORKBENCH_TITLE}=mount-data
    Create PersistenVolume Storage    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                               size=${PV_SIZE}    connected_workbench=${NONE}     press_cancel=${TRUE}    project_title=${PRJ_TITLE}
    Create PersistenVolume Storage    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                               size=${PV_SIZE}    connected_workbench=${workbenchs}   project_title=${PRJ_TITLE}
    Storage Should Be Listed    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                         type=Persistent storage    connected_workbench=${workbenchs}
    Check Corresponding PersistentVolumeClaim Exists    storage_name=${pv_name}    namespace=${ns_name}
    Storage Size Should Be    name=${pv_name}    namespace=${ns_name}  size=${PV_SIZE}

Verify User Can Create And Start A Workbench With Existent PV Storage
    [Tags]    ODS-1814
    ${pv_name}=    Set Variable    ${PV_BASENAME}-existent
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create PersistenVolume Storage    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                               size=${PV_SIZE}    connected_workbench=${NONE}    project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_2_TITLE}  workbench_description=${WORKBENCH_2_DESCRIPTION}  prj_title=${PRJ_TITLE}
    ...                 image_name=${NB_IMAGE}   deployment_size=Small  storage=Persistent  pv_existent=${TRUE}
    ...                 pv_name=${pv_name}  pv_description=${NONE}  pv_size=${NONE}
    Workbench Should Be Listed      workbench_title=${WORKBENCH_2_TITLE}
    Workbench Status Should Be      workbench_title=${WORKBENCH_2_TITLE}      status=${WORKBENCH_STATUS_STARTING}
    # continue on failure is temporary
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_2_TITLE}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Check Corresponding Notebook CR Exists      workbench_title=${WORKBENCH_2_TITLE}   namespace=${ns_name}

Verify User Can Create And Start A Workbench Adding A New PV Storage
    [Tags]    ODS-1816
    ${pv_name}=    Set Variable    ${PV_BASENAME}-new
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_3_TITLE}  workbench_description=${WORKBENCH_3_DESCRIPTION}  prj_title=${PRJ_TITLE}
    ...                 image_name=${NB_IMAGE}   deployment_size=Small  storage=Persistent  pv_existent=${FALSE}
    ...                 pv_name=${pv_name}  pv_description=${PV_DESCRIPTION}  pv_size=${PV_SIZE}
    Workbench Should Be Listed      workbench_title=${WORKBENCH_3_TITLE}
    Reload Page
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    Workbench Status Should Be      workbench_title=${WORKBENCH_3_TITLE}      status=${WORKBENCH_STATUS_STARTING}
    # the continue on failure should be temporary
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_3_TITLE}
    Check Corresponding Notebook CR Exists      workbench_title=${WORKBENCH_3_TITLE}   namespace=${ns_name}
    Reload Page
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    ${connected_woksps}=    Create List    ${WORKBENCH_3_TITLE}
    Storage Should Be Listed    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                         type=Persistent storage    connected_workbench=${connected_woksps}
    Storage Size Should Be    name=${pv_name}    namespace=${ns_name}  size=${PV_SIZE}

Verify User Can Stop A Workbench
    [Tags]    ODS-1817
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Stop Workbench    workbench_title=${WORKBENCH_TITLE}    press_cancel=${TRUE}
    Stop Workbench    workbench_title=${WORKBENCH_TITLE}
    # add checks on notebook pod is terminated but CR is present

Verify User Can Launch A Workbench
    [Tags]    ODS-1815
    Open Data Science Projects Home Page
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Start Workbench     workbench_title=${WORKBENCH_TITLE}
    Launch Workbench    workbench_title=${WORKBENCH_TITLE}
    Check Launched Workbench Is The Correct One     workbench_title=${WORKBENCH_TITLE}     image=${NB_IMAGE}    namespace=${ns_name}
    # Switch Window      Open Data Hub

Verify User Can Stop A Workbench From Projects Home Page
    [Tags]    ODS-1823
    Open Data Science Projects Home Page
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    ${_}    ${workbench_cr_name}=    Get Openshift Notebook CR From Workbench    workbench_title=${WORKBENCH_TITLE}    namespace=${ns_name}
    Stop Workbench From Projects Home Page     workbench_title=${WORKBENCH_TITLE}   project_title=${PRJ_TITLE}  workbench_cr_name=${workbench_cr_name}    namespace=${ns_name}
    Workbench Launch Link Should Be Disabled    workbench_title=${WORKBENCH_TITLE}  project_title=${PRJ_TITLE}
    # add checks on notebook pod is terminated but CR is present

Verify User Can Start And Launch A Workbench From Projects Home Page
    [Tags]    ODS-1818
    Open Data Science Projects Home Page
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    ${_}    ${workbench_cr_name}=    Get Openshift Notebook CR From Workbench    workbench_title=${WORKBENCH_TITLE}    namespace=${ns_name}
    Start Workbench From Projects Home Page     workbench_title=${WORKBENCH_TITLE}   project_title=${PRJ_TITLE}  workbench_cr_name=${workbench_cr_name}    namespace=${ns_name}
    Launch Workbench From Projects Home Page    workbench_title=${WORKBENCH_TITLE}  project_title=${PRJ_TITLE}
    Check Launched Workbench Is The Correct One     workbench_title=${WORKBENCH_TITLE}     image=${NB_IMAGE}    namespace=${ns_name}
    # Switch Window      Open Data Hub

 Verify User Can Delete A Workbench
    [Tags]    ODS-1813
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Delete Workbench    workbench_title=${WORKBENCH_TITLE}    press_cancel=${TRUE}
    Delete Workbench    workbench_title=${WORKBENCH_TITLE}
    Workbench Should Not Be Listed    workbench_title=${WORKBENCH_TITLE}
    Check Workbench CR Is Deleted    workbench_title=${WORKBENCH_TITLE}   namespace=${ns_name}

Verify User Can Delete A Persistent Storage
    [Tags]    ODS-1824
    ${pv_name}=    Set Variable    ${PV_BASENAME}-TO-DELETE
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create PersistenVolume Storage    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                               size=${PV_SIZE}    connected_workbench=${NONE}   project_title=${PRJ_TITLE}
    Delete Storage    name=${pv_name}    press_cancel=${TRUE}
    Delete Storage    name=${pv_name}    press_cancel=${FALSE}
    Storage Should Not Be Listed    name=${pv_name}
    Check Storage PersistentVolumeClaim Is Deleted    storage_name=${pv_name}    namespace=${ns_name}

Verify User Cand Add A S3 Data Connection
    [Tags]    ODS-1825
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_S3_NAME}    aws_access_key=${S3.AWS_ACCESS_KEY_ID}
    ...                          aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}    aws_s3_endpoint=${DC_S3_ENDPOINT}    aws_region=${DC_S3_REGION}
    Data Connection Should Be Listed    name=${DC_S3_NAME}    type=${DC_S3_TYPE}    connected_workbench=${NONE}
    Check Corresponding Data Connection Secret Exists    dc_name=${DC_S3_NAME}    namespace=${ns_name}

Verify User Can Delete A Data Connection
    [Tags]    ODS-1826
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Delete Data Connection    name=${DC_S3_NAME}   press_cancel=${True}
    Delete Data Connection    name=${DC_S3_NAME}
    Data Connection Should Not Be Listed    name=${DC_S3_NAME}
    Check Data Connection Secret Is Deleted    dc_name=${DC_S3_NAME}    namespace=${ns_name}

Verify User Can Create A Workbench With Environment Variables
    [Tags]    ODS-1864
    ${envs_var_secrets}=    Create Dictionary    secretA=TestVarA   secretB=TestVarB  k8s_type=Secret  input_type=${KEYVALUE_TYPE}
    ${envs_var_cm}=         Create Dictionary    cmA=TestVarA-CM   cmB=TestVarB-CM  k8s_type=Config Map  input_type=${KEYVALUE_TYPE}
    ${envs_list}=    Create List   ${envs_var_secrets}     ${envs_var_cm}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_TITLE}-envs  workbench_description=${WORKBENCH_DESCRIPTION}  prj_title=${PRJ_TITLE}
    ...                 image_name=${NB_IMAGE}   deployment_size=Small  storage=Ephemeral  pv_existent=${NONE}
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}  press_cancel=${FALSE}    envs=${envs_list}
    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE}-envs
    Launch Workbench    workbench_title=${WORKBENCH_TITLE}-envs
    Check Environment Variables Exist    exp_env_variables=${envs_list}


Verify User Can Delete A Data Science Project
    [Tags]    ODS-1784
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Delete Data Science Project   project_title=${PRJ_TITLE}
    Check Project Is Deleted    namespace=${ns_name}
    # check workbenchs and resources get deleted too


*** Keywords ***
Project Suite Setup
    Set Library Search Order    SeleniumLibrary
    ${to_delete}=    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    # RHOSi Setup

Project Suite Teardown
    Close All Browsers
    # Delete All Data Science Projects From CLI
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}

Set Variables For User Access Test
    Set Suite Variable    ${PRJ_1_USER3}    ${PRJ_TITLE}-${TEST_USER_3.USERNAME}-#1
    Set Suite Variable    ${PRJ_2_USER3}    ${PRJ_TITLE}-${TEST_USER_3.USERNAME}-#2
    Set Suite Variable    ${PRJ_A_USER4}    ${PRJ_TITLE}-${TEST_USER_4.USERNAME}-#A
    Append To List    ${PROJECTS_TO_DELETE}    ${PRJ_1_USER3}    ${PRJ_2_USER3}    ${PRJ_A_USER4}

Launch Data Science Project Main Page
    [Arguments]     ${username}=${TEST_USER_3.USERNAME}     ${password}=${TEST_USER_3.PASSWORD}    ${ocp_user_auth_type}=${TEST_USER_3.AUTH_TYPE}
    Launch Dashboard    ocp_user_name=${username}  ocp_user_pw=${password}  ocp_user_auth_type=${ocp_user_auth_type}   browser_options=${BROWSER.OPTIONS}
    Open Data Science Projects Home Page

Create Project With Empty Title And Expect Error
    ${error_rgx}=   Set Variable    Element[ a-zA-Z=\(\)\[\]"'\/\s]+was not enabled[ a-zA-Z=\(\)\[\]"'\/\s0-9.]+
    Run Keyword And Expect Error    Element*was not enabled*   Create Data Science Project    title=${EMPTY}  description=${EMPTY}

Create Project With Special Chars In Resource Name And Expect Error
    ${error_rgx}=   Set Variable    Element[ a-zA-Z=\(\)\[\]"'\/\s]+was not enabled[ a-zA-Z=\(\)\[\]"'\/\s0-9.]+
    Run Keyword And Expect Error    Element*was not enabled*   Create Data Science Project    title=${EMPTY}  description=${EMPTY}    resource_name=ods-ci-@-project#name

Check Corresponding Namespace Exists
    [Arguments]     ${project_title}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${project_title}
    Oc Get      kind=Project    name=${ns_name}
    [Return]    ${ns_name}

Check Corresponding Notebook CR Exists
    [Arguments]     ${workbench_title}  ${namespace}
    ${res}  ${response}=    Get Openshift Notebook CR From Workbench   workbench_title=${workbench_title}  namespace=${namespace}
    IF    "${response}" == "${EMPTY}"
        Run Keyword And Continue On Failure    Fail    msg=Notebook CR not found for ${workbench_title} in ${namespace} NS
    END

Check Workbench CR Is Deleted
    [Arguments]    ${workbench_title}   ${namespace}    ${timeout}=10s
    ${status}=      Run Keyword And Return Status    Check Corresponding Notebook CR Exists   workbench_title=${workbench_title}   namespace=${namespace}
    IF    ${status} == ${TRUE}
        Fail    msg=The notebook CR for ${workbench_title} is still present, while it should have been deleted.
    END

Check Corresponding Data Connection Secret Exists
    [Arguments]     ${dc_name}  ${namespace}
    ${res}  ${response}=    Get Openshift Secret From Data Connection   dc_name=${dc_name}  namespace=${namespace}
    IF    "${response}" == "${EMPTY}"
        Run Keyword And Continue On Failure    Fail    msg=Secret not found for ${dc_name} in ${namespace} NS
    END

Check Data Connection Secret Is Deleted
    [Arguments]    ${dc_name}   ${namespace}    ${timeout}=10s
    ${status}=      Run Keyword And Return Status    Check Corresponding Data Connection Secret Exists    dc_name=${dc_name}    namespace=${namespace}
    IF    ${status} == ${TRUE}
        Fail    msg=The secret for ${dc_name} data connection is still present, while it should have been deleted.
    END

Check Corresponding PersistentVolumeClaim Exists
    [Arguments]     ${storage_name}  ${namespace}
    ${res}  ${response}=    Get Openshift PVC From Storage   name=${storage_name}  namespace=${namespace}
    IF    "${response}" == "${EMPTY}"
        Run Keyword And Continue On Failure    Fail    msg=PVC not found for ${storage_name} in ${namespace} NS
    END

Check Storage PersistentVolumeClaim Is Deleted
    [Arguments]    ${storage_name}   ${namespace}    ${timeout}=10s
    ${status}=      Run Keyword And Return Status    Check Corresponding PersistentVolumeClaim Exists    storage_name=${storage_name}    namespace=${namespace}
    IF    ${status} == ${TRUE}
        Fail    msg=The PVC for ${storage_name} storage is still present, while it should have been deleted.
    END

Check Project Is Deleted
    [Arguments]    ${namespace}
    Wait Until Keyword Succeeds    10s    1s    Namespace Should Not Exist    namespace=${namespace}

Check Environment Variables Exist
    [Arguments]    ${exp_env_variables}
    Open With JupyterLab Menu  File  New  Notebook
    Sleep  1s
    Maybe Close Popup
    Maybe Select Kernel
    Sleep   3s
    # Add and Run JupyterLab Code Cell in Active Notebook    import os
    FOR    ${idx}   ${env_variable_dict}    IN ENUMERATE    @{exp_env_variables}
        Remove From Dictionary    ${env_variable_dict}     k8s_type    input_type
        # IF    "${input_type}" == "${KEYVALUE_TYPE}"
        ${n_pairs}=    Get Length    ${env_variable_dict.keys()}
        FOR  ${pair_idx}   ${key}  ${value}  IN ENUMERATE  &{env_variable_dict}
            Log   ${pair_idx}-${key}-${value}
            Run Keyword And Continue On Failure     Run Cell And Check Output    import os;print(os.environ["${key}"])    ${value}
            Capture Page Screenshot
        END
        # END
    END
    Open With JupyterLab Menu    Edit    Select All Cells
    Open With JupyterLab Menu    Edit    Delete Cells

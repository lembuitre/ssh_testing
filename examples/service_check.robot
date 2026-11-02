*** Settings ***
Documentation      Run explicitly against a Linux host with systemd.
Resource           ../resources/project.robot
Suite Setup        Connect To Server
Suite Teardown     Disconnect From Servers
Test Tags          service

*** Variables ***
${SERVICE_NAME}     %{SERVICE_NAME=}

*** Test Cases ***
Configured Service Is Running
    Wait Until Keyword Succeeds    ${POLL_TIMEOUT}    ${POLL_INTERVAL}
    ...    Service Should Be Running    ${SERVICE_NAME}

*** Settings ***
Documentation    Put project-specific actions here; keep SSH plumbing in ssh.robot.
Resource         ssh.robot

*** Keywords ***
Get Remote Hostname
    ${output}=    Run Remote Command    hostname
    ${hostname}=    Strip String    ${output}
    RETURN    ${hostname}

Service Should Be Running
    [Documentation]    Example for Linux hosts using systemd; no service is started or restarted.
    [Arguments]    ${service_name}
    Should Not Be Empty    ${service_name}    Set SERVICE_NAME to the service to verify.
    ${service}=    Quote Remote Argument    ${service_name}
    ${output}=    Run Remote Command    systemctl is-active -- ${service}
    ${status}=    Strip String    ${output}
    Should Be Equal    ${status}    active

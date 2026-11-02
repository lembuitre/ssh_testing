*** Settings ***
Documentation      Minimal read-only checks for a Linux/Unix SSH target.
Resource           ../resources/project.robot
Suite Setup        Connect To Server
Suite Teardown     Disconnect From Servers
Test Tags          smoke

*** Test Cases ***
Remote Host Has A Name
    ${hostname}=    Get Remote Hostname
    Should Not Be Empty    ${hostname}

Remote Command Returns Expected Output
    ${output}=    Run Remote Command    printf 'ssh-template-ready'
    Should Be Equal    ${output}    ssh-template-ready

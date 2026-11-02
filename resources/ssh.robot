*** Settings ***
Documentation    Shared SSH operations only. Add application behavior in project.robot.
Library          SSHLibrary
Library          OperatingSystem
Library          String
Resource         ../config/environment.robot

*** Keywords ***
Connect To Server
    [Documentation]    Open one connection; password/passphrase are read only when logging in.
    [Arguments]    ${host}=${SSH_HOST}    ${user}=${SSH_USER}    ${port}=${SSH_PORT}    ${alias}=server
    Should Not Be Empty    ${host}    Set SSH_HOST before running.
    Should Not Be Empty    ${user}    Set SSH_USER before running.
    IF    $SSH_AUTH not in ('password', 'key')
        Fail    SSH_AUTH must be password or key.
    END
    IF    $SSH_AUTH == 'key'
        Should Not Be Empty    ${SSH_KEYFILE}    Set SSH_KEYFILE for key authentication.
        OperatingSystem.File Should Exist    ${SSH_KEYFILE}
    ELSE
        ${password}=    OperatingSystem.Get Environment Variable    SSH_PASSWORD    ${EMPTY}
        Should Not Be Empty    ${password}    Set SSH_PASSWORD for password authentication.
    END
    SSHLibrary.Open Connection    ${host}    alias=${alias}    port=${port}    timeout=${SSH_CONNECT_TIMEOUT}
    TRY
        IF    $SSH_AUTH == 'key'
            SSHLibrary.Login With Public Key    ${user}    ${SSH_KEYFILE}    password=%{SSH_KEY_PASSPHRASE=}
        ELSE
            SSHLibrary.Login    ${user}    ${password}
        END
    EXCEPT    AS    ${error}
        SSHLibrary.Close Connection
        Fail    ${error}
    END

Disconnect From Servers
    SSHLibrary.Close All Connections

Use Server
    [Arguments]    ${alias}
    SSHLibrary.Switch Connection    ${alias}

Run Remote Command
    [Documentation]    Return stdout after checking the remote exit code. Commands run in separate shells.
    [Arguments]    ${command}    ${expected_rc}=0    ${timeout}=${SSH_COMMAND_TIMEOUT}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    ${command}
    ...    return_stdout=True    return_stderr=True    return_rc=True    timeout=${timeout}
    Should Be Equal As Integers    ${rc}    ${expected_rc}
    ...    msg=Remote command returned ${rc}; expected ${expected_rc}. stderr: ${stderr}
    RETURN    ${stdout}

Remote Output Should Contain
    [Arguments]    ${command}    ${expected_text}
    ${output}=    Run Remote Command    ${command}
    Should Contain    ${output}    ${expected_text}

Wait For Remote Output
    [Documentation]    Poll a read-only command. Do not retry commands that change remote state.
    [Arguments]    ${command}    ${expected_text}    ${timeout}=${POLL_TIMEOUT}    ${interval}=${POLL_INTERVAL}
    Wait Until Keyword Succeeds    ${timeout}    ${interval}
    ...    Remote Output Should Contain    ${command}    ${expected_text}

Upload File
    [Arguments]    ${local_path}    ${remote_path}
    OperatingSystem.File Should Exist    ${local_path}
    SSHLibrary.Put File    ${local_path}    ${remote_path}

Download File
    [Arguments]    ${remote_path}    ${local_path}
    SSHLibrary.Get File    ${remote_path}    ${local_path}

Quote Remote Argument
    [Documentation]    Quote one value for a POSIX shell. Do not quote an entire command with this.
    [Arguments]    ${value}
    ${quoted}=    Evaluate    shlex.quote(str($value))    modules=shlex
    RETURN    ${quoted}

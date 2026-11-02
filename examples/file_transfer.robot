*** Settings ***
Documentation      Requires SFTP and mktemp; writes only its own temporary remote files.
Resource           ../resources/ssh.robot
Suite Setup        Connect To Server
Suite Teardown     Disconnect From Servers
Test Tags          transfer

*** Test Cases ***
Upload And Download Preserve File Contents
    ${remote_dir}=    Run Remote Command    mktemp -d /tmp/robot-ssh-template.XXXXXXXX
    ${remote_dir}=    Strip String    ${remote_dir}
    ${quoted_dir}=    Quote Remote Argument    ${remote_dir}
    TRY
        ${local_dir}=    Evaluate    tempfile.mkdtemp(prefix='robot-ssh-template-')    modules=tempfile
        TRY
            ${source}=    Set Variable    ${local_dir}${/}source.txt
            ${destination}=    Set Variable    ${local_dir}${/}download.txt
            OperatingSystem.Create File    ${source}    SSH template transfer example.\n
            Upload File    ${source}    ${remote_dir}/sample.txt
            SSHLibrary.File Should Exist    ${remote_dir}/sample.txt
            Download File    ${remote_dir}/sample.txt    ${destination}
            ${expected}=    OperatingSystem.Get File    ${source}
            ${actual}=    OperatingSystem.Get File    ${destination}
            Should Be Equal    ${actual}    ${expected}
        FINALLY
            OperatingSystem.Remove Directory    ${local_dir}    recursive=True
        END
    FINALLY
        Run Remote Command    rm -f -- ${quoted_dir}/sample.txt && rmdir -- ${quoted_dir}
    END

# SSH automation template

A small Robot Framework template derived from `dc-voma-rf-testing`.
It keeps the familiar suite → shared keywords → SSHLibrary structure and
removes the DCM/VoMA, customer/version, packet-generator, Jira, email,
Selenium, CSV and custom proxy dependencies.

## Files

| File | What to change for your project |
| --- | --- |
| `config/environment.robot` | Non-secret connection defaults and timeouts |
| `resources/ssh.robot` | Reusable connection, command, polling and transfer keywords |
| `resources/project.robot` | Your application's actions and assertions |
| `tests/smoke.robot` | Default read-only example tests |
| `examples/service_check.robot` | Optional systemd service check |
| `examples/file_transfer.robot` | Optional SFTP upload/download with temporary-file cleanup |
| `run.py` | Small cross-platform runner; forwards Robot CLI arguments |
| `requirements.txt` | Two direct dependencies; pip installs their dependencies |

There are no circular resource imports or custom Python Robot libraries.
Examples live outside `tests/` so a default run only performs smoke checks.

## 1. Install

Use Python 3.10–3.12 for this starting baseline. From the extracted folder:

```bash
python -m venv .venv
```

Activate it on Linux/macOS:

```bash
source .venv/bin/activate
```

Or in Windows PowerShell:

```powershell
.venv\Scripts\Activate.ps1
```

Then install and validate the suite structure without connecting:

```bash
python -m pip install -r requirements.txt
python run.py --dryrun tests examples
```

The dependency versions retain Robot Framework 7.0 from the source framework
and select SSHLibrary 3.8.0 as a baseline. They are not a complete lock of
transitive dependencies. After validating in your environment, keep a lock
appropriate to your project's dependency policy.

## 2. Configure authentication

Set these variables in the same terminal where you run the tests. The host
below is an example: replace it and the username with your target values.
Do not put passwords or private keys in the Robot files.

Linux/macOS, password authentication:

```bash
export SSH_HOST=server.example.com
export SSH_USER=automation
export SSH_AUTH=password
read -rsp 'SSH password: ' SSH_PASSWORD
export SSH_PASSWORD
printf '\n'
```

Windows PowerShell, password authentication:

```powershell
$env:SSH_HOST = 'server.example.com'
$env:SSH_USER = 'automation'
$env:SSH_AUTH = 'password'
$env:SSH_PASSWORD = [System.Net.NetworkCredential]::new('', (Read-Host 'SSH password' -AsSecureString)).Password
```

For key authentication, set `SSH_AUTH=key` and `SSH_KEYFILE` to the absolute
path of your private key. If encrypted, also set `SSH_KEY_PASSPHRASE` securely.
`SSH_PASSWORD` is unused in key mode. For example, in Bash:

```bash
export SSH_AUTH=key
export SSH_KEYFILE="$HOME/.ssh/id_rsa"
# Only for an encrypted key:
read -rsp 'Key passphrase: ' SSH_KEY_PASSPHRASE
export SSH_KEY_PASSPHRASE
printf '\n'
```

| Setting | Default | Purpose |
| --- | --- | --- |
| `SSH_HOST` | Empty, required | Target host or IP |
| `SSH_USER` | Empty, required | SSH account |
| `SSH_PORT` | `22` | SSH TCP port |
| `SSH_AUTH` | `password` | `password` or `key` |
| `SSH_PASSWORD` | Empty | Required for password mode |
| `SSH_KEYFILE` | Empty | Required local private-key path for key mode |
| `SSH_KEY_PASSPHRASE` | Empty | Optional key passphrase |
| `SSH_CONNECT_TIMEOUT` | `15 seconds` | Connection timeout setting |
| `SSH_COMMAND_TIMEOUT` | `30 seconds` | Per-command execution limit |
| `POLL_TIMEOUT` / `POLL_INTERVAL` | `30 seconds` / `2 seconds` | Polling defaults |

The last four settings are Robot variables, configurable in
`config/environment.robot` or with `--variable`. Other settings above are
environment variables; the non-secret ones can also be overridden with
Robot's `--variable`. A `.env` file is **not** loaded automatically.

## 3. Run

```bash
python run.py
python run.py --include smoke tests
python run.py --test "Remote Host Has A Name" tests
python run.py --variable SSH_COMMAND_TIMEOUT:60s tests
python run.py --outputdir results/qa --variable SSH_HOST:qa.example.com tests
```

With no arguments, the runner selects `tests`. When passing arguments,
include the target path at the end. The runner resolves relative paths from
the template folder, even when called from elsewhere.

Reports are `results/report.html`, `results/log.html`, and `results/output.xml`.
The process returns Robot's exit code so failed tests fail a CI job.
For direct Robot usage, run from the template folder:

```bash
python -m robot --outputdir results tests
```

Optional examples (run explicitly):

```bash
python run.py --variable SERVICE_NAME:sshd examples/service_check.robot
python run.py examples/file_transfer.robot
```

The service example only reads status and requires systemd. The transfer
example requires SFTP, `mktemp`, and a writable `/tmp`; it creates a unique
directory, transfers a sample file, compares contents, and cleans up in
`FINALLY`. Interrupted processes or lost SSH sessions can prevent cleanup.

## 4. Adapt to another project

1. Copy this folder and rename it for your project.
2. Set the target and authentication through your shell or CI secret store.
3. Add application keywords in `resources/project.robot`.
4. Copy `tests/smoke.robot` to start a new suite. Keep suite setup and teardown.
5. Replace the example assertions, then run `python run.py --dryrun tests`
   followed by a live run against your test target.

For example, an application keyword can verify a version:

```robotframework
Application Version Should Be
    [Arguments]    ${expected}
    ${actual}=    Run Remote Command    /opt/my-app/bin/my-app --version
    Should Contain    ${actual}    ${expected}
```

Useful shared operations:

```robotframework
${text}=    Run Remote Command    uname -s
${text}=    Run Remote Command    test -f /tmp/missing-file    expected_rc=1
Wait For Remote Output    cat /tmp/my-app-status.txt    ready
Upload File    ${CURDIR}/input.txt    /tmp/input.txt
Download File    /tmp/output.txt    ${OUTPUT DIR}/output.txt
```

`Run Remote Command` checks the exit code and returns stdout. A nonzero
exit code fails unless explicitly expected. It includes stderr on failure.
Poll only read-only commands: retries can repeat side effects. A polling
deadline may be exceeded by a final command attempt; use a suitable command
timeout too.

For multiple hosts, open each with a unique alias in your suite setup:

```robotframework
Connect To Targets
    Connect To Server    host=app.example.com    alias=app
    Connect To Server    host=db.example.com    alias=db
    Use Server    app
```

Use `Suite Setup    Connect To Targets` and keep
`Suite Teardown    Disconnect From Servers`. `Use Server` switches the active
connection; subsequent commands and transfers use it. This minimal example
shares the configured authentication across hosts. Extend configuration only
when your project needs different credentials or keys per host.

## Changes from the original

| Original responsibility | Template equivalent |
| --- | --- |
| `common.robot` connection/proxy branches | `resources/ssh.robot`, direct SSHLibrary only |
| `command.robot` / `template.robot` application flows | `resources/project.robot`, generic examples |
| Customer/version data and server YAML | One small Robot config plus environment variables |
| Custom SSH proxy backend | Removed; direct network access required |
| Jira cycle scripts, email and metrics | Standard Robot reports and exit status |
| Telecom packet, alarm and CSV test suites | Two smoke tests plus optional examples |

This is a reusable starter, not a drop-in replacement for the original
telecom regression suite. The uploaded archive is unchanged; no original
credentials, hosts, customer data, generated reports or Git history are included.

## Operational notes and verification

- The examples target a POSIX shell on Linux/Unix. Windows runners are
  supported by `run.py`; Windows SSH targets need different commands.
- Each `Execute Command` starts a separate shell. Combine related operations
  in one command, e.g. `cd /opt/my-app && ./my-app --version`.
- Use `Quote Remote Argument` for variable values embedded in shell commands.
- A command timeout limits waiting; it does not guarantee the remote process
  has stopped. Add application-specific cleanup for long-running tasks.
- No automatic reconnect, sudo, interactive prompt handling, bastion or SOCKS
  behavior is included. Add these only when needed by your project.
- This template adds no host-key verification policy. Review SSHLibrary's
  behavior and your environment's host identity requirements before deployment.
- Robot logs and output XML can contain resolved arguments, command output
  and secrets, especially at DEBUG/TRACE. Restrict report access and avoid
  secrets in commands. Environment variables do not guarantee log redaction.

Authoring checks verified local resource paths, import direction, control
block balance, and Python runner syntax. Runtime verification is pending:
package-index access was blocked in the authoring environment, and no SSH
test target was supplied. Run the dry run and live smoke checks above before
adopting the template. A dry run does not test authentication or commands.

References: [SSHLibrary source and keyword documentation](https://github.com/MarketSquare/SSHLibrary),
[Robot Framework User Guide](https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html).

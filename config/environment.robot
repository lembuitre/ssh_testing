*** Variables ***
# Set environment variables before running. Robot --variable overrides these.
${SSH_HOST}                %{SSH_HOST=}
${SSH_PORT}                %{SSH_PORT=22}
${SSH_USER}                %{SSH_USER=}
${SSH_AUTH}                %{SSH_AUTH=password}
${SSH_KEYFILE}             %{SSH_KEYFILE=}
${SSH_CONNECT_TIMEOUT}     15 seconds
${SSH_COMMAND_TIMEOUT}     30 seconds
${POLL_TIMEOUT}            30 seconds
${POLL_INTERVAL}           2 seconds

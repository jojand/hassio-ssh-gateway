#!/bin/sh

KEY_PATH="/root/.ssh/private_key"
KEY_DIR="/root/.ssh"
OPTIONS_PATH="/data/options.json"
CONFIG=$(cat $OPTIONS_PATH)
TAILS=""

echo "hassio-ssh-gateway"

PRIVATE_KEY=$(jq -r '.privateKey' ${OPTIONS_PATH})

mkdir -p ${KEY_DIR}
echo "${PRIVATE_KEY}" > ${KEY_PATH}
chmod 600 ${KEY_PATH}

for row in $(echo "${CONFIG}" | jq -c '.tunnels[]'); do
  name="$(echo "$row" | jq -c -r '.name')"
  forward_string="$(echo "$row" | jq -c -r '.forwardString')"
  remote_host="$(echo "$row" | jq -c -r '.remoteHost')"
  remote_port="$(echo "$row" | jq -c -r '.remotePort')"

  echo "Setting up $name ..."
  echo "forwardString: $forward_string"
  echo "remoteHost: $remote_host"
  echo "remotePort: $remote_port"
  echo ""
  touch /var/log/autossh_${name}.log
  TAILS="$TAILS /var/log/autossh_${name}.log"
  
  AUTOSSH_DEBUG=1 AUTOSSH_LOGFILE=/var/log/autossh_${name}.log /usr/bin/autossh -f -M 0 -o StrictHostKeyChecking=no -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -i ${KEY_PATH} -nNT -R ${forward_string} -p ${remote_port} ${remote_host}
done

tail -f ${TAILS}

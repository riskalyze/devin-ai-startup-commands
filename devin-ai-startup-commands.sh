#!/usr/bin/env bash

set -eo pipefail

pushd ~
DEBIAN_FRONTEND=noninteractive
sudo apt update
sudo apt install curl unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --bin-dir /usr/bin --install-dir /usr/local/aws-cli --update

# secrets in devin.ai env
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region us-east-2
aws codeartifact login --tool npm --domain riskalyze --domain-owner $AWS_SHARED_ACCOUNT_ID --namespace rsk --repository npm

popd

if [ -z $(which mise) ] 
then
  curl https://raw.githubusercontent.com/riskalyze/devin-ai-startup-commands/refs/heads/main/mise.run | sh
  echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
  mise trust -a
fi
mise install

echo "deb [trusted=yes] https://packages.twingate.com/apt/ /" | sudo tee /etc/apt/sources.list.d/twingate.list
sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/twingate.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
sudo apt install -yq twingate
echo "${DEVIN_TWINGATE_ACCESS}" | sudo twingate setup --headless -
MAX_RETRIES=5
WAIT_TIME=5
n=0

while [ $n -lt $MAX_RETRIES ]; do
  echo "Starting Twingate service..."
  set +xe
  twingate start

  echo "Waiting $WAIT_TIME seconds for Twingate service to start..."
  sleep $WAIT_TIME

  status=$(twingate status)
  echo "Twingate service status: '$status'"

  if [ "$status" = "online" ]; then
    echo "Twingate service is connected."
    break
  else
    twingate stop
  fi

  # Increment the retry counter and wait time
  n=$((n+1))
  WAIT_TIME=$((WAIT_TIME+5))

  echo "Twingate service is not connected. Retrying ..."
done

if [ $n -eq $MAX_RETRIES ]; then
  echo "Twingate service failed to connect."
  exit 1
fi

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
aws codeartifact login --tool npm --domain riskalyze --domain-owner 125149417810 --namespace rsk --repository npm
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 125149417810.dkr.ecr.us-east-2.amazonaws.com  

popd

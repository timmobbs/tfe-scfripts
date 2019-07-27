#!/usr/bin/env bash
# Bash script for running terraform apply in a concourse linux container
# Parameters:
#   app         - terraform application subdir to build (Note "core" is just considered anouther application).
#   environment - environment to deploy to. Used to grab a variables file per environement and copy it into the terraform app dir.
# Environment Vars:
#    AWS_ACCESS_KEY_ID
#    AWS_SECRET_ACCESS_KEY
#    TF_TOKEN

# Fail on errors and missing env vars
set -eu
# Fail on pipe errors
set -o pipefail

if [ $# -ne 2 ]
then
  echo "Usage `basename $0` <app> <environment>"
  exit 1
fi

#todo validate inputs
app=$1
environment=$2

script_dir="$( cd "$( dirname "$0" )" >/dev/null && pwd )"

#call the setup file to setup the config files and call terraform init
source ${script_dir}/terraform_setup.bash $app $environment

#auto apply the plan
terraform apply -auto-approve


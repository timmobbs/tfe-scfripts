#!/usr/bin/env bash
# Bash script for running terraform plan in a concourse linux container
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

#set +e because tfplan returns non 0 success codes
set +e
terraform plan -detailed-exitcode
tfout=$?
set -e

echo "Terraform Plan returned $tfout"

# The exit code that we will return because we return 0 for non changes and needs apply
# for any other code we will return non zero so as to fail the ci pipeline
exit_code=2

case "$tfout" in
"0")
  echo "Terraform state no change"
  exit_code=0
  ;;
"1")
  echo "ERROR -Terraform plan failed"
  exit_code=1
  ;;
"2")
  echo "Terraform plan needs apply"
  exit_code=0
  ;;
*)
  echo "ERROR - Unkown Terraform exit code $tfout"
  ;;
esac

mkdir -p tf_output
echo "$tfout" > tf_output/out.txt

exit $exit_code

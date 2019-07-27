#!/usr/bin/env bash
# Bash script for setting up terraform in a concourse linux container.  Includes terraform init
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

#Check correct parameter usage
if [ $# -ne 2 ]
then
  echo "Usage `basename $0` <app> <environment>"
  exit 1
fi

base_dir="$PWD"
#todo validate inputs
app=$1
environment=$2

#Construct global dir paths from relative paths (So it doesn't matter where this is called from)
app_dir="${base_dir}/terraform/${app}"
config_dir="${base_dir}/terraform/${app}/env/${environment}"

if [ ! -d "$app_dir" ]
then
  echo "Can not find a valid terraform app dir at ${app_dir}"
  exit 1
fi

if [ ! -d "$config_dir" ]
then
  echo "Can not find a valid terraform config dir at ${config_dir}"
  exit 1
fi

echo "app_dir is ${app_dir}"
echo "config_dir is ${config_dir}"

#Copy configuration files to the correct directories
cp ${config_dir}/${environment}.auto.tfvars ${app_dir}
cp ${app_dir}/env/remote.tf ${base_dir}


pushd ${app_dir} > /dev/null

#Get the aws keys from the environemnt and write out a variable file with them in.
# This is because using TFE remote backend doesn't support reading the environment vars
if [ -n "${AWS_ACCESS_KEY_ID:-}" ] && [ -n "${AWS_SECRET_ACCESS_KEY:-}" ]
then

  cat <<EOF > secrets.auto.tfvars
  aws_access_key="${AWS_ACCESS_KEY_ID}" 
  aws_secret_key="${AWS_SECRET_ACCESS_KEY}"
EOF
fi

# TODO this was so we could pass vars to concourse.  Need to rewrite this for jenkins in a simpler way to 
# just pass in any environment vars that start with TF_VAR
if [ -n "${TF_VAR_NAME1:-}" ] && [ -n "${TF_VAR_VALUE1-}" ] 
then
  cat <<EOF >> secrets.auto.tfvars
${TF_VAR_NAME1}="${TF_VAR_VALUE1}"
EOF
fi

popd > /dev/null


#Write out the terraformrc file with the TFE token if it's in an environment var
if [ -n "${TF_TOKEN:-}" ]
then
  pushd ~ > /dev/null
  cat <<EOF > .terraformrc
credentials "terraform.lululemon.app" {
  token = "${TF_TOKEN}"
}
EOF
  popd > /dev/null
fi

#setup and run the appropriate terraform command
rm -rf .terraform
set +e #don't check output init always returns 1 with the remote backend
terraform init
set -e

#TODO this needs to be changes for terraform 0.12
terraform workspace select ${environment}


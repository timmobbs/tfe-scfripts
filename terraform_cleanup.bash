#!/usr/bin/env bash
# Bash script for cleaning up after terraform_setup and any additional plan and apply have been run. 
# Parameters:
#   app         - terraform application subdir to build (Note "core" is just considered anouther application).
#   environment - environment to deploy to. Used to grab a variables file per environement and copy it into the terraform app dir.


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

# Helper function to cleanup the copied remote.tf and tfvars files
cleanupTerraformConfigs () {
  if [ ! -z "${app_dir+x}" ] 
  then
    rm -f ${app_dir}/${environment}.auto.tfvars
    rm -f ${base_dir}/remote.tf
    rm -f ${app_dir}/awskeys.auto.tfvars
    rm -f ${app_dir}/secrets.auto.tfvars
    rm -rf ${base_dir}/.terraform
  fi
}

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

#Cleanup the copies here
cleanupTerraformConfigs


# Check if we set a TF_TOKEN by env var. If so then we delete the token file.
if [ ! -z "${TF_TOKEN+x}" ] && [ "${TF_TOKEN}" != '' ]
then 
  rm -f ~/.terraformrc
fi

echo "`basename $0` complete"


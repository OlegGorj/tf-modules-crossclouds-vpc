#!/bin/bash -e

# Params:
#   $1 - project id
#   $2 - environment (test, dev, qa)
#   $3 - credentials file
#

# 1. script creates gcp credentials file under ~/.config/gcloud
# 2. generates remote backend TF script

FILE_ARG='<Cloud provider (GCP or AWS)> <GCP project id (only for Cloud Provider - GCP)> <environment (test/dev/prod)> <path to json service account key file>'

if [ "$#" -lt 3 ]; then
  echo 'Error: missing argument.'
  echo "$0 ${FILE_ARG}"
  exit 1
fi

function trim_lr() {
  echo $(echo $1| sed 's,^ *,,; s, *$,,')
}

function timestamp() {
  date +"%Y-%m-%d_%H-%M-%S"
}

function to_lower() {
  echo $1 | tr "[:upper:]" "[:lower:]"
}


CLOUD=$(to_lower $(trim_lr $1))
if [[ $CLOUD != "aws" ]] && [[ $CLOUD != "gcp" ]]; then
  echo "Error: Invalid Cloud Provider <aws or gcp>"
  exit 1
fi

if [ ${CLOUD} == "gcp" ]; then
  GCP_PRJ=$(to_lower $(trim_lr $2))
  ENV=$(to_lower $(trim_lr $3))
  CREDS_FILE=$(to_lower $(trim_lr $4))

elif [ ${CLOUD} == "aws" ]
then
  ENV=$(to_lower $(trim_lr $2))
  CREDS_FILE=$(to_lower $(trim_lr $3))

fi

SERVICE_ACCOUNT=terraform
CREDS_FILE_DIR=~/.config/gcloud
#CREDS_FILE_PATH="${CREDS_FILE_DIR}/credentials_crosscloud.json"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TFVARS_DIR_PATH="${THIS_DIR}/terraform"
TFVARS_FILE_PATH="${TFVARS_DIR_PATH}/terraform.tfvars"
#TFVAR_CREDS='gcp_credentials_file_path'
TFBACKEND_FILE_PATH="${TFVARS_DIR_PATH}/backend.tf"

function createTFVars() {
  if [ ! -e $1 ]; then
    echo "/*" > $1
    echo " * Initialized Terraform variables." >> $1
    echo " */" >> $1
  fi
}

# If not already present, add a key-value to tfvars file.
# arguments: tfvars_path_file_name key value
function addTFVar() {
  if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo 'Error: missing argument for addTFVar().'
    exit 1
  fi

  local VAR_NAME="$2"
  local KEY_EXISTS="$(cat $1 | grep $2)"

  if [ -z "${KEY_EXISTS}" ]; then
    echo "" >> $1
    echo "$2 = \"$3\"" >> $1
    echo "Updated $2 in $1."
  fi
}

# generate backend TF file
# params: path_backend_file.tf project environment
function createTFBackend() {
  if [ ! -e $1 ]; then
    echo "/*" > $1
    echo " * Initialized Terraform GCP backend." >> $1
    echo " */" >> $1

cat >> $1 <<EOF
terraform {
 backend "gcs" {
   bucket = "${2}"
   prefix  = "terraform/state/${3}"
 }
}
EOF

  fi
}

# main section

ALLOWED_IP_RANGE=$(curl ifconfig.co)

createTFBackend "${TFBACKEND_FILE_PATH}" "${GCP_PRJ}" "${ENV}"

createTFVars "${TFVARS_FILE_PATH}"

if [ ${CLOUD} == "gcp" ]; then
  addTFVar "${TFVARS_FILE_PATH}" "gcp_credentials_file_path" "${CREDS_FILE}"
  addTFVar "${TFVARS_FILE_PATH}" "gcp_project_id" "${GCP_PRJ}"
elif [ ${CLOUD} == "aws" ]
then
  addTFVar "${TFVARS_FILE_PATH}" "aws_credentials_file_path" "${CREDS_FILE}"
fi
addTFVar "${TFVARS_FILE_PATH}" "environment" "${ENV}"
#addTFVar "${TFVARS_FILE_PATH}" "tf_ssh_key" "${TF_VAR_ssh_key}"
#addTFVar "${TFVARS_FILE_PATH}" "tf_ssh_private_key_file" "${TF_VAR_ssh_private_key}"
addTFVar "${TFVARS_FILE_PATH}" "source_ranges_ips" "${ALLOWED_IP_RANGE}"

#cat << EOF > $TF_ENV.tfvars
#env = "$TF_ENV"
#region = "$GOOGLE_REGION"
#billing_account = "$TF_VAR_billing_account"
#org_id = "$TF_VAR_org_id"
#domain = "$GOOGLE_ADMIN_DOMAIN"
#admin_account="$GOOGLE_ADMIN_ACCOUNT"
#g_folder = "$FULL_FOLDER_ID"
#g_folder_id = "$FOLDER_ID"
#admin_project = "$TF_PROJECT_ID"
#source_ranges_ips = "$ALLOWED_IP_RANGE/32"
#tf_ssh_key = "$TF_VAR_ssh_key"
#tf_ssh_private_key_file = "$TF_VAR_ssh_private_key"
#EOF

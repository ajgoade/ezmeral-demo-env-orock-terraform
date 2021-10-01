#!/bin/bash

#export PATH=$PATH:/Users/jaideepjoshi/Library/Python/3.9/bin

set -u
set -e
set -o pipefail

source "./scripts/variables.sh"

echo "Installing HPECP cli on local Mac"
pip3 install --quiet --upgrade --user hpecp

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

# Test CLI is able to connect
echo "Platform ID: $(hpecp license platform-id)"

# create Orock infra using Terraform and install ECP
./bin/create_new_environment_from_scratch.sh

exec > >(tee -i generated/log-$(basename $0).txt)
exec 2>&1

#source "./scripts/variables.sh"
source "./scripts/functions.sh"

print_header "Configuring Global Active Directory in HPE CP"
./scripts/01_configure_global_active_directory.sh
echo "Configured Global Active Directory"

print_header "Adding a Gateway to HPE CP"
./scripts/02_gateway_add.sh

if [[ "${INSTALL_WITH_SSL}" == "True" ]]; then
   print_header "Setting Gateway SSL"
   ./scripts/03_set_gateway_ssl.sh
fi

tput setaf 2
echo "ECP Controller and Gateway Installed"
tput sgr0

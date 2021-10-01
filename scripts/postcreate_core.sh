#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

source "./scripts/functions.sh"

#export HPECP_CONFIG_FILE=./generated/hpecp.conf
#export HPECP_LOG_CONFIG_FILE=./generated/hpecp_cli_logging.conf

#HPECP_VERSION=$(hpecp config get --query 'objects.[bds_global_version]' --output text)
#HPECP_VERSION=$(hpecp version)
#echo "HPECP Version: ${HPECP_VERSION}"

#print_header "Configuring Global Active Directory in HPE CP"
#./scripts/01_configure_global_active_directory.sh
#echo "Configred Global Active Directory"

print_header "Adding a Gateway to HPE CP"
#./scripts/02_gateway_add.sh

#if [[ "${INSTALL_WITH_SSL}" == "True" ]]; then
#   print_header "Setting Gateway SSL"
##   ./scripts/03_set_gateway_ssl.sh
#fi

#print_header "Configuring Active Directory in Demo Tenant"
#.scripts/setup_demo_tenant_ad.sh

#print_header "Enable Virtual Nodes on Controller"
#./bin/experimental/epic_enable_virtual_node_assignment.sh

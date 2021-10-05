#!/bin/bash

source "./scripts/functions.sh"
source "./scripts/00b-load-env-variables.sh"

exec > >(tee -i generated/$(basename $0).log)
exec 2>&1

tput setaf 2
echo "Installing/Configuring ECP Controller"
tput sgr0
./scripts/03a-controller-install-rpms.sh

tput setaf 2
echo "Installing ECP Controller"
tput sgr0
./scripts/03b-controller-install-ecp.sh

tput setaf 2
echo "Create HPECP conf file"
tput sgr0
./scripts/03c-create-hpecp-conf.sh

tput setaf 2
echo "Configuring Controller to use AD/LDAP server"
tput sgr0
./scripts/03d-configure-global-active-directory.sh
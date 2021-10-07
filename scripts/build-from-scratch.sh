#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

#these old entries can cause issues later
[ -e ~/.ssh/known_hosts ] && rm ~/.ssh/known_hosts

source "./scripts/functions.sh"
source "./scripts/00b-load-env-variables.sh"

tput setaf 3
echo "Begin Install"
tput sgr0

sleep 10

./scripts/01-*
./scripts/02-*
./scripts/03-*
./scripts/04-*
./scripts/05-*
./scripts/06-* /api/v2/k8scluster/1
./scripts/07-*

tput setaf 3
echo "Wow! Got this far??!!"
tput sgr0

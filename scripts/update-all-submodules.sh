#!/bin/bash

set -o errexit -o nounset -o pipefail
# this line enables debugging
set -xv

git submodule foreach git pull origin master

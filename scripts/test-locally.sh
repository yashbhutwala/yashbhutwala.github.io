#!/bin/bash

set -o errexit -o nounset -o pipefail
# this line enables debugging
set -xv

hugo --debug server -D

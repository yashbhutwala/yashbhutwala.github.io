#!/bin/bash

set -o errexit -o nounset -o pipefail
# this line enables debugging
set -xv

# https://gohugo.io/content-management/archetypes
POST_NAME="${1:-"my-first-post.md"}"
hugo --debug new "post/$POST_NAME"

#!/usr/bin/env bash
echo "WARNING: 'sysctl $*' was swallowed because it doesn't work in a container, make sure you've set it via 'docker run --sysctl'."

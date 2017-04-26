#!/bin/bash

set -e

# Use this script to build docker images.

DOCKER=docker


$DOCKER build -t maxking/mailman-core core/
$DOCKER build -t maxking/mailman-web web/

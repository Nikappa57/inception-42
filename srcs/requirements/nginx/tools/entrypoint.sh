#!/bin/bash

# test the conf
nginx -t
if [ $? -ne 0 ]; then
    echo "ERROR: configuration failed"
    exit 1
fi
echo "configuration is ok!"
echo "starting nginx..."

exec nginx -g "daemon off;"
#!/usr/bin/env bash

echoBeep() {
    afplay /System/Library/Sounds/Glass.aiff
}

cd ./cryptocards_token_contracts
./deploy.sh -s -f

cd ../cryptocards_contracts
./deploy.sh -s -v -f
./deploy.sh -s -v -i

cd ../cryptocards_token_contracts
./deploy.sh -s -i

cd ../cryptocards_contracts
./deploy.sh -s -v -l

echoBeep

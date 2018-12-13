#!/usr/bin/env bash

inHouseAccount=
networkName=
verbose=
reset=

usage()
{
    echo "usage: ./deploy.sh [[-v] [-n [local|ropsten|mainnet]] | [-h]]"
    echo "  -n | --network [local|ropsten|mainnet]    Deploys contracts to the specified network (default is local)"
    echo "  -r | --reset                              Run all migrations from the beginning, instead of running from the last completed migration"
    echo "  -v | --verbose                            Outputs verbose logging"
    echo "  -h | --help                               Displays this help screen"
}

echoHeader() {
    echo " "
    echo "-----------------------------------------------------------"
    echo "-----------------------------------------------------------"
}

setEnvVars()
{
    if [ "$networkName" == "ropsten" ]; then
        inHouseAccount="0xb5d35673278ee2d2b1290e700cc081eecda1fcbf"     # Account 2
    elif [ "$networkName" == "mainnet" ]; then
        inHouseAccount=""
    else
        networkName="local"
        inHouseAccount="0x6729d17818174b92180453599789328FEe5E74Cd"     # Account ?
    fi

    export CCC_IN_HOUSE_ACCOUNT="$inHouseAccount"
    export CCC_VERBOSE_LOGS="$verbose"
}

deploy()
{
    if [ "$networkName" == "local" ]; then
        echoHeader
        echo "NOTE: Be sure to run the Oraclize Ethereum-bridge first!"
        echo "CMD: ethereum-bridge -H localhost:7545 -a 1 --dev"
    else
        echoHeader
        echo "NOTE: Be sure to remove the Oraclize Address Resolver from the Controller Contract!"
        echo "LINE: OAR = OraclizeAddrResolverI( ... )"
    fi

    echoHeader
    echo "Clearing previous build..."
    rm -rf build/

    echoHeader
    echo "Compiling Contracts.."
    truffle compile

    echoHeader
    echo "Running Contract Migrations.."
    echo " - using network: $networkName"
    if [ "$reset" == "yes" ]; then
        echo " - resetting previous migrations"
        truffle migrate --network "$networkName" --reset
    else
        echo " - continuing from last migration"
        truffle migrate --network "$networkName"
    fi

    echoHeader
    echo "Contract Deployment Complete!"
    echo " "
}

while [ "$1" != "" ]; do
    case $1 in
        -v | --verbose )        verbose="yes"
                                ;;
        -r | --reset )          reset="yes"
                                ;;
        -n | --network )        shift
                                networkName=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

setEnvVars
deploy


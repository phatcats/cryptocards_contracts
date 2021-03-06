#!/usr/bin/env bash

# Phat Cats - Crypto-Cards
#  - https://crypto-cards.io
#  - https://phatcats.co
#
# Copyright 2019 (c) Phat Cats, Inc.

# Ganache Local Accounts
#  - 1 = Not used
#  - 2 = Oracle Bridge
#  - 3 = Contract Proxy Admin
#  - 4 = Contract Owner
#  - 5 = Treasury In-House Account
#  - 6 = Test User A
#  - 7 = Test User B
#  - 8 = Test User C

freshLoad=
initialize=
linkContracts=
runTransactions=
runErc20Migration=
runErc721Migration=
proxyAdmin=
ownerAccount=
inHouseAccount=
networkId=
networkName="local"
verbose=
silent=

usage() {
    echo "usage: ./deploy.sh [[-n [local|ropsten|mainnet] [-f] [-v]] | [-h]]"
    echo "  -n    | --network [local|ropsten|mainnet]    Deploys contracts to the specified network (default is local)"
    echo "  -f    | --fresh                              Run all deployments from the beginning, instead of updating"
    echo "  -i    | --initialize                         Run Contract Initializations"
    echo "  -l    | --link                               Run Contract Linking"
    echo "  -t    | --transactions                       Run Test Transactions (Local Only)"
    echo "  -m20  | --migrate20                          Run ERC20 Token Migration"
    echo "  -m721 | --migrate721                         Run ERC721 Token Migration"
    echo "  -v    | --verbose                            Outputs verbose logging"
    echo "  -s    | --silent                             Suppresses the Beep at the end of the script"
    echo "  -h    | --help                               Displays this help screen"
}

echoHeader() {
    echo " "
    echo "-----------------------------------------------------------"
    echo "-----------------------------------------------------------"
}

echoBeep() {
    [[ -z "$silent" ]] && {
        afplay /System/Library/Sounds/Glass.aiff
    }
}

setEnvVars() {
    export $(egrep -v '^#' .env | xargs)

    if [[ "$networkName" == "ropsten" ]]; then
        networkId="3"
        networkProvider="ropsten"
        proxyAdmin="$ROPSTEN_PROXY_ADMIN"
        ownerAccount="$ROPSTEN_OWNER_ACCOUNT"
        inHouseAccount="$ROPSTEN_IN_HOUSE_ACCOUNT"
    elif [ "$networkName" == "mainnet" ]; then
        networkId="1"
        networkProvider="mainnet"
        proxyAdmin="$MAINNET_PROXY_ADMIN"
        ownerAccount="$MAINNET_OWNER_ACCOUNT"
        inHouseAccount="$MAINNET_IN_HOUSE_ACCOUNT"
    else
        networkName="local"
        networkId="5777"
        networkProvider="dev-5777"
        proxyAdmin="$LOCAL_PROXY_ADMIN"
        ownerAccount="$LOCAL_OWNER_ACCOUNT"
        inHouseAccount="$LOCAL_IN_HOUSE_ACCOUNT"
    fi

    walletMnemonicType="proxy"
    [[ -n "$initialize" || -n "$runTransactions" || -n "$linkContracts" || -n "$runErc20Migration" || -n "$runErc721Migration" ]] && {
        walletMnemonicType="owner"
    }

    # Pass State to Truffle Scripts
    export CCC_WALLET_MNEMONIC_TYPE="$walletMnemonicType"
    export CCC_NETWORK_NAME="$networkName"
    export CCC_NETWORK_PROVIDER="$networkProvider"
    export CCC_NETWORK_ID="$networkId"
    export CCC_VERBOSE_LOGS="$verbose"
}

startSession() {
    echoHeader
    fromAccount="Contract Owner"
    [[ "$1" == "$proxyAdmin" ]] && {
        fromAccount="Proxy Admin"
    }
    echo "Starting ZOS Session from $fromAccount"
    echo " - using proxyAdmin: $proxyAdmin"
    echo " - using owner:      $ownerAccount"
    echo " - using network:    $networkName"
    zos session --network "$networkName" --from "$1" --expires 3600 --timeout 3600
}

deployFresh() {
    startSession "$proxyAdmin"

    if [[ "$networkName" == "local" ]]; then
        echoHeader
        echo "NOTE: Be sure to run the Oraclize Ethereum-bridge first!"
        echo "CMD: ethereum-bridge -H localhost:7545 -a 1 --dev"
    else
        echoHeader
        echo "NOTE: Be sure to remove the Oraclize Address Resolver from the Oracle Contract!"
        echo "LINE: OAR = OraclizeAddrResolverI( ... )"
    fi

    echoHeader
    echo "Clearing previous build..."
    rm -rf build/
    rm -r "./zos.$networkProvider.json"

    echoHeader
    if [[ "$networkName" == "local" ]]; then
        echo "Deploying with dependencies..."
        zos push --deploy-dependencies
    else
        echo "Deploying without dependencies..."
        zos push
    fi

    echoHeader
    echo "Creating Contract: CryptoCardsOracle"
    oracleAddress=$(zos create CryptoCardsOracle --init initialize --args "$ownerAccount")
    sleep 1s

    echoHeader
    echo "Creating Contract: CryptoCardsTreasury"
    treasuryAddress=$(zos create CryptoCardsTreasury --init initialize --args "$ownerAccount")
    sleep 1s

    echoHeader
    echo "Creating Contract: CryptoCardsLib"
    libAddress=$(zos create CryptoCardsLib --init initialize --args "$ownerAccount")
    sleep 1s

    echoHeader
    echo "Creating Contract: CryptoCardsGum"
    gumAddress=$(zos create CryptoCardsGum --init initialize --args "$ownerAccount")
    sleep 1s

    echoHeader
    echo "Creating Contract: CryptoCardsCards"
    cardsAddress=$(zos create CryptoCardsCards --init initialize --args "$ownerAccount")
    sleep 1s

    echoHeader
    echo "Creating Contract: CryptoCardsPacks"
    packsAddress=$(zos create CryptoCardsPacks --init initialize --args "$ownerAccount")
    sleep 1s

    echoHeader
    echo "Creating Contract: CryptoCardsTokenMigrator"
    tokenMigrator=$(zos create CryptoCardsTokenMigrator --init initialize --args "$ownerAccount")
    sleep 1s

    echoHeader
    echo "Creating Contract: CryptoCardsController"
    controllerAddress=$(zos create CryptoCardsController --init initialize --args "$ownerAccount")
    sleep 1s

    echoHeader
    echo "Contract Addresses: "
    echo " - controllerAddress: ${controllerAddress:(-42)}"
    echo " - oracleAddress:     ${oracleAddress:(-42)}"
    echo " - treasuryAddress:   ${treasuryAddress:(-42)}"
    echo " - packsAddress:      ${packsAddress:(-42)}"
    echo " - cardsAddress:      ${cardsAddress:(-42)}"
    echo " - gumAddress:        ${gumAddress:(-42)}"
    echo " - tokenMigrator:     ${tokenMigrator:(-42)}"
    echo " - libAddress:        ${libAddress:(-42)}"

    echoHeader
    echo "Contract Deployment Complete!"
    echo " "
    echoBeep
}

deployUpdate() {
    startSession "$proxyAdmin"

    echo " "
    echo "Pushing Contract Updates.."
    zos push

    echo "Updating Logic Contracts.."
    zos update CryptoCardsLib
    zos update CryptoCardsGum
    zos update CryptoCardsCards
    zos update CryptoCardsPacks
    zos update CryptoCardsTreasury
    zos update CryptoCardsOracle
    zos update CryptoCardsTokenMigrator
    zos update CryptoCardsController

    echo " "
    echo "Contract Updates Complete!"
    echo " "
    echoBeep
}

runInitializations() {
    startSession "$ownerAccount"

    echoHeader
    echo "Initializing Contracts..."
    truffle exec ./scripts/initializations.js --network "$networkName"
    echoBeep
}

runContractLinking() {
    startSession "$ownerAccount"

    echoHeader
    echo "Linking Token Contracts..."
    truffle exec ./scripts/link_tokens.js --network "$networkName"
    echoBeep
}

runTransactions() {
    startSession "$ownerAccount"

    echoHeader
    echo "Running Test Transactions..."
    truffle exec ./scripts/transactions.js --network "$networkName"
    echoBeep
}

runErc20Migration() {
    startSession "$ownerAccount"

    echoHeader
    echo "Running ERC20 Token Migration..."
    truffle exec ./scripts/migrate_erc20.js --network "$networkName"
    echoBeep
}

runErc721Migration() {
    startSession "$ownerAccount"

    echoHeader
    echo "Running ERC721 Token Migration..."
    truffle exec ./scripts/migrate_erc721.js --network "$networkName"
    echoBeep
}


while [[ "$1" != "" ]]; do
    case $1 in
        -n | --network )        shift
                                networkName=$1
                                ;;
        -f | --fresh )          freshLoad="yes"
                                ;;
        -i | --initialize )     initialize="yes"
                                ;;
        -l | --link )           linkContracts="yes"
                                ;;
        -t | --transactions )   runTransactions="yes"
                                ;;
        -m20 | --migrate20 )    runErc20Migration="yes"
                                ;;
        -m721 | --migrate721 )  runErc721Migration="yes"
                                ;;
        -v | --verbose )        verbose="yes"
                                ;;
        -s | --silent )         silent="yes"
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

if [[ -n "$freshLoad" ]]; then
    deployFresh
elif [[ -n "$linkContracts" ]]; then
    runContractLinking
elif [[ -n "$runTransactions" ]]; then
    runTransactions
elif [[ -n "$runErc20Migration" ]]; then
    runErc20Migration
elif [[ -n "$runErc721Migration" ]]; then
    runErc721Migration
elif [[ -n "$initialize" ]]; then
    runInitializations
else
    deployUpdate
fi

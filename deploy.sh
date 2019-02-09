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
runTransactions=
proxyAdmin=
ownerAccount=
inHouseAccount=
networkId=
networkName="local"
verbose=

usage() {
    echo "usage: ./deploy.sh [[-n [local|ropsten|mainnet] [-f] [-v]] | [-h]]"
    echo "  -n | --network [local|ropsten|mainnet]    Deploys contracts to the specified network (default is local)"
    echo "  -f | --fresh                              Run all deployments from the beginning, instead of updating"
    echo "  -i | --initialize                         Run Contract Initializations"
    echo "  -t | --transactions                       Run Load-Test Transactions (Local Only)"
    echo "  -v | --verbose                            Outputs verbose logging"
    echo "  -h | --help                               Displays this help screen"
}

echoHeader() {
    echo " "
    echo "-----------------------------------------------------------"
    echo "-----------------------------------------------------------"
}

setEnvVars() {
    export $(egrep -v '^#' .env | xargs)

    if [ "$networkName" == "ropsten" ]; then
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
    [ -n "$initialize" -o -n "$runTransactions" ] && {
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
    [ "$1" == "$proxyAdmin" ] && {
        fromAccount="Proxy Admin"
    }
    echo "Starting ZOS Session from $fromAccount"
    echo " - using proxyAdmin: $proxyAdmin"
    echo " - using owner: $ownerAccount"
    echo " - using network: $networkName"
    zos session --network "$networkName" --from "$1" --expires 3600
}

deployFresh() {
    startSession "$proxyAdmin"

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
    rm -r "./zos.$networkProvider.json"

    echoHeader
    if [ "$networkName" == "local" ]; then
        echo "Deploying with dependencies..."
        zos push --deploy-dependencies
    else
        echo "Deploying without dependencies..."
        zos push
    fi

    echoHeader
    echo "Creating Contract: CryptoCardsOracle"
    oracleAddress=$(zos create CryptoCardsOracle --init initialize --args "$ownerAccount")
#    echo "oracleAddress: $oracleAddress"

    echoHeader
    echo "Creating Contract: CryptoCardsTreasury"
    treasuryAddress=$(zos create CryptoCardsTreasury --init initialize --args "$ownerAccount")
#    echo "treasuryAddress: $treasuryAddress"

    echoHeader
    echo "Creating Contract: CryptoCardsLib"
    libAddress=$(zos create CryptoCardsLib --init initialize --args "$ownerAccount")
#    echo "libAddress: $libAddress"

    echoHeader
    echo "Creating Contract: CryptoCardsGum"
    gumAddress=$(zos create CryptoCardsGum --init initialize --args "$ownerAccount")
    echo "Creating Token: CryptoCardsGumToken - StandaloneERC20"
    gumTokenAddress=$(zos create openzeppelin-eth/StandaloneERC20 --init initialize --args "CryptoCardsGum","GUM",18,2000000000000000000000000000,"$gumAddress",[],[])   # <-- 2 Billion, 18 Decimals
#    echo "gumAddress: $gumAddress"
#    echo "gumTokenAddress: $gumTokenAddress"

    echoHeader
    echo "Creating Contract: CryptoCards"
    cardsAddress=$(zos create CryptoCards --init initialize --args "$ownerAccount")
    echo "Creating Cards Token: CryptoCardsERC721"
    cardsTokenAddress=$(zos create CryptoCardsERC721 --init initialize --args "$ownerAccount","CryptoCards","CARD",["$ownerAccount"],["$ownerAccount"])
#    echo "cardsAddress: $cardsAddress"
#    echo "cardsTokenAddress: $cardsTokenAddress"

    echoHeader
    echo "Creating Contract: CryptoCardPacks"
    packsAddress=$(zos create CryptoCardPacks --init initialize --args "$ownerAccount")
    echo "Creating Packs Token: CryptoCardsERC721"
    packsTokenAddress=$(zos create CryptoCardsERC721 --init initialize --args "$ownerAccount","CryptoCardPacks","PACK",["$ownerAccount"],["$ownerAccount"])
#    echo "packsAddress: $packsAddress"
#    echo "packsTokenAddress: $packsTokenAddress"

    echoHeader
    echo "Creating Contract: CryptoCardsController"
    controllerAddress=$(zos create CryptoCardsController --init initialize --args "$ownerAccount")
#    echo "controllerAddress: $controllerAddress"

    echoHeader
    echo "Contract Deployment Complete!"
    echo " "
}

deployUpdate() {
    startSession "$proxyAdmin"

    echo " "
    echo "Pushing Contract Updates.."
    zos push

    echo "Updating Logic Contracts.."
    zos update CryptoCardsERC721
    zos update CryptoCardsLib
    zos update CryptoCardsGum
    zos update CryptoCards
    zos update CryptoCardPacks
    zos update CryptoCardsTreasury
    zos update CryptoCardsOracle
    zos update CryptoCardsController

    echo " "
    echo "Contract Updates Complete!"
    echo " "
}

runInitializations() {
    startSession "$ownerAccount"

    echoHeader
    echo "Running Contract Initializations..."
    truffle exec ./scripts/initializations.js --network "$networkName"
}

runTransactions() {
    startSession "$ownerAccount"

    echoHeader
    echo "Running Load-Test Transactions..."
    truffle exec ./scripts/transactions.js --network "$networkName"
}


while [ "$1" != "" ]; do
    case $1 in
        -n | --network )        shift
                                networkName=$1
                                ;;
        -f | --fresh )          freshLoad="yes"
                                ;;
        -i | --initialize )     initialize="yes"
                                ;;
        -t | --transactions )   runTransactions="yes"
                                ;;
        -v | --verbose )        verbose="yes"
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

if [ -n "$freshLoad" ]; then
    deployFresh
elif [ -n "$runTransactions" ]; then
    runTransactions
elif [ -n "$initialize" ]; then
    runInitializations
else
    deployUpdate
fi

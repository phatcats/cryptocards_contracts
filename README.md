# Crypto-Cards Contracts v1.2.1
Homepage: https://crypto-cards.io
Ropsten: https://ropsten.crypto-cards.io

Copyright (c) 2018 Phat Cats, Inc.


## How to deploy

1. Download and install the latest Oraclize Ethereum Bridge at https://github.com/oraclize/ethereum-bridge

2. Create a ".env" file in the root directory with the following ENV VARs:

        ROPSTEN_INFURA_API_KEY="__your_ropsten_api_key_here__"
        MAINNET_INFURA_API_KEY="__your_mainnet_api_key_here__'

        ROPSTEN_WALLET_MNEMONIC="__your_ropsten_wallet_mnemonic_here__"
        MAINNET_WALLET_MNEMONIC="__your_mainnet_wallet_mnemonic_here__"

        IN_HOUSE_ACCOUNT="__your_public_eth_address_here__"
        VERBOSE_LOGS=yes

    Note: A wallet mnemonic looks like: "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat"
    Note: If you don't have an Infura API Key, get one for free at https://infura.io/

3. Start your local RPC Test Server (Ganache?)

4. Connect to your Oraclize Ethereum Bridge:

        $ ethereum-bridge -H localhost:7545 -a 1 --dev

    Wait for this stage to complete, and find the OAR address from the output, which looks like the following:

        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);

5. Make sure the address matches the code found at "contracts/CryptoCardsController.sol" line 80.
    Update the code to reflect the address you received, if necessary.

6. a. Deploy the Solidity Contracts to your local blockchain

        $ ./deploy.sh -r -v

    b. Deploy the Solidity Contracts to Ropsten Test Net

        $ ./deploy.sh -r -v -n ropsten

7. Once they are successfully deployed, you can grab the Contract Addresses from the Output.

    Note: When deployed to any network other than local, you will have to manually unpause the controller contract.


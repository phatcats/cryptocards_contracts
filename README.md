# Crypto-Cards Contracts v1.2.1
Homepage: https://crypto-cards.io
Ropsten:  https://ropsten.crypto-cards.io
PhatCats: https://phatcats.co

Copyright 2019 (c) Phat Cats, Inc.

## Recommended Wallet Test Accounts:
- 1 = Not used
- 2 = Oracle Bridge
- 3 = Contract Proxy Admin
- 4 = Contract Owner
- 5 = Treasury In-House Account
- 6 = Test User A
- 7 = Test User B
- 8 = Test User C

## How to deploy

1. Download and install the latest Oraclize Ethereum Bridge at https://github.com/oraclize/ethereum-bridge

2. Create a ".env" file in the root directory with the following ENV VARs:

        LOCAL_PROXY_ADMIN="__your_public_eth_address_here__"
        LOCAL_OWNER_ACCOUNT="__your_public_eth_address_here__"
        LOCAL_IN_HOUSE_ACCOUNT="__your_public_eth_address_here__"
        LOCAL_BOUNTY_ACCOUNT="__your_public_eth_address_here__"
        LOCAL_MARKETING_ACCOUNT="__your_public_eth_address_here__"
        LOCAL_EXCHANGE_ACCOUNT="__your_public_eth_address_here__"


        ROPSTEN_PROXY_ADMIN="__your_public_eth_address_here__"
        ROPSTEN_OWNER_ACCOUNT="__your_public_eth_address_here__"
        ROPSTEN_IN_HOUSE_ACCOUNT="__your_public_eth_address_here__"
        ROPSTEN_BOUNTY_ACCOUNT="__your_public_eth_address_here__"
        ROPSTEN_MARKETING_ACCOUNT="__your_public_eth_address_here__"
        ROPSTEN_EXCHANGE_ACCOUNT="__your_public_eth_address_here__"

        ROPSTEN_INFURA_API_KEY="__your_ropsten_api_key_here__"
        ROPSTEN_WALLET_MNEMONIC_PROXY="__your_wallet_private_key_here__"
        ROPSTEN_WALLET_MNEMONIC_OWNER="__your_wallet_private_key_here__"


        MAINNET_PROXY_ADMIN="__your_public_eth_address_here__"
        MAINNET_OWNER_ACCOUNT="__your_public_eth_address_here__"
        MAINNET_IN_HOUSE_ACCOUNT="__your_public_eth_address_here__"
        MAINNET_BOUNTY_ACCOUNT="__your_public_eth_address_here__"
        MAINNET_MARKETING_ACCOUNT="__your_public_eth_address_here__"
        MAINNET_EXCHANGE_ACCOUNT="__your_public_eth_address_here__"

        MAINNET_INFURA_API_KEY="__your_mainnet_api_key_here__"
        MAINNET_WALLET_MNEMONIC_PROXY="__your_wallet_private_key_here__"
        MAINNET_WALLET_MNEMONIC_OWNER="__your_wallet_private_key_here__"


    Note: A wallet mnemonic may be used in place of a private key, but in that case only Account 1 of the Wallet is accessible.  This may cause issues for the Proxy Admin account.
    Note: If you don't have an Infura API Key, get one for free at https://infura.io/

3. Start your local RPC Test Server (Ganache?)

4. Connect to your Oraclize Ethereum Bridge:

        $ ethereum-bridge -H localhost:7545 -a 1 --dev

    Wait for this stage to complete, and find the OAR address from the output, which looks like the following:

        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);

5. Make sure the address matches the code found at "contracts/CryptoCardsOracle.sol" line 54.
    Update the code to reflect the address you received, if necessary.

6. a. Deploy the Solidity Contracts to your local blockchain

        $ ./deploy.sh -f -v

    b. Deploy the Solidity Contracts to Ropsten Test Net

        $ ./deploy.sh -f -v -n ropsten

7. Once they are successfully deployed, you can grab the Contract Addresses from the Output.

    Note: When deployed to any network other than local, you will have to manually unpause the controller contract.

8. After making changes to the Contracts, they can be upgraded to your local blockchain

        $ ./deploy.sh -v

    or the Ropsten Test Net

        $ ./deploy.sh -v -n ropsten


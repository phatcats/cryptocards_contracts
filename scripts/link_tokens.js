/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2019 (c) Phat Cats, Inc.
 */
'use strict';

require('dotenv').config();

// Required by zos-lib when running from truffle
global.artifacts = artifacts;
global.web3 = web3;

const { Contracts } = require('zos-lib');
const { Lib } = require('./common');
const { networkOptions } = require('../config');
const _ = require('lodash');

const CryptoCardsERC20 = Contracts.getFromLocal('CryptoCardsERC20');
const CryptoCardsERC721 = Contracts.getFromLocal('CryptoCardsERC721');
const CryptoCardsTreasury = Contracts.getFromLocal('CryptoCardsTreasury');
const CryptoCardsOracle = Contracts.getFromLocal('CryptoCardsOracle');
const CryptoCardsLib = Contracts.getFromLocal('CryptoCardsLib');
const CryptoCardsGum = Contracts.getFromLocal('CryptoCardsGum');
const CryptoCards = Contracts.getFromLocal('CryptoCards');
const CryptoCardPacks = Contracts.getFromLocal('CryptoCardPacks');
const CryptoCardsController = Contracts.getFromLocal('CryptoCardsController');

Lib.network = process.env.CCC_NETWORK_NAME;
Lib.networkProvider = process.env.CCC_NETWORK_PROVIDER;
Lib.networkId = process.env.CCC_NETWORK_ID;
Lib.verbose = (process.env.CCC_VERBOSE_LOGS === 'yes');

const _tokenAddress = {
    local: {
        packs : '0x01b9707dD7782bB441ec57C1B62D669896859096',
        cards : '0x89eC3f11E1600BEd981DD2d12404bAAF21c7699c',
        gum   : '0xF70B61E3800dFFDA57cf167051CAa0Fb6bA1B0B3'
    },
    ropsten: {
        packs : '0xF21cFBe2C36E0718602F8a65c4B7dA35e60cf85F',
        cards : '0x7Afc9b2D33FE3c23077a36B8Eff29760C51F10d7',
        gum   : '0x1FdA6f4B52c6E06D5C471a4c1979ee2f32F4FD5a'
    },
    mainnet: {
        packs : '',
        cards : '',
        gum   : ''
    }
};

module.exports = async function() {
    Lib.log({separator: true});
    let nonce = 0;
    let totalGas = 0;
    let receipt;
    if (_.isUndefined(networkOptions[Lib.network])) {
        Lib.network = 'local';
    }

    const options = networkOptions[Lib.network];
    const owner = process.env[`${_.toUpper(Lib.network)}_OWNER_ACCOUNT`];
    const tokenAddress = _tokenAddress[Lib.network];

    Lib.deployData = require(`../zos.${Lib.networkProvider}.json`);

    const _getTxOptions = () => {
        return {from: owner, nonce: nonce++, gasPrice: options.gasPrice};
    };

    if (Lib.verbose) {
        Lib.log({separator: true});
        Lib.log({msg: `Network:   ${Lib.network}`});
        Lib.log({msg: `Web3:      ${web3.version}`});
        Lib.log({msg: `Gas Price: ${Lib.fromWeiToGwei(options.gasPrice)} GWEI`});
        Lib.log({msg: `Owner:     ${owner}`});
        Lib.log({separator: true});
    }

    try {
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Get Transaction Nonce
        nonce = (await Lib.getTxCount(owner)) || 0;
        Lib.log({msg: `Starting at Nonce: ${nonce}`});
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({spacer: true});


        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Get Deployed Contracts
        const ddCryptoCardsGum = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsGum');
        const cryptoCardsGum = Lib.getContractInstance(CryptoCardsGum, ddCryptoCardsGum.address);

        const ddCryptoCards = Lib.getDeployDataFor('cryptocardscontracts/CryptoCards');
        const cryptoCards = Lib.getContractInstance(CryptoCards, ddCryptoCards.address);

        const ddCryptoCardPacks = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardPacks');
        const cryptoCardPacks = Lib.getContractInstance(CryptoCardPacks, ddCryptoCardPacks.address);

        const ddCryptoCardsController = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsController');
        const cryptoCardsController = Lib.getContractInstance(CryptoCardsController, ddCryptoCardsController.address);


        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Contract Token Linking

        //
        // CryptoCardsGum
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Gum to ERC20 Token...'});
        Lib.verbose && Lib.log({msg: `ERC20 Token: ${tokenAddress.gum}`, indent: 1});
        receipt = await cryptoCardsGum.setGumToken(tokenAddress.gum, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCards
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Cards to ERC721 Token...'});
        Lib.verbose && Lib.log({msg: `ERC721 Cards Token: ${tokenAddress.cards}`, indent: 1});
        receipt = await cryptoCards.setErc721Token(tokenAddress.cards, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCardPacks
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Packs to ERC721 Token...'});
        Lib.verbose && Lib.log({msg: `ERC721 Packs Token: ${tokenAddress.packs}`, indent: 1});
        receipt = await cryptoCardPacks.setErc721Token(tokenAddress.packs, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCardsController
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Controller to ERC721 Tokens...'});
        Lib.verbose && Lib.log({msg: `Cards Token: ${tokenAddress.cards}`, indent: 1});
        receipt = await cryptoCardsController.setCardsTokenAddress(tokenAddress.cards, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;
        Lib.verbose && Lib.log({msg: `Packs Token: ${tokenAddress.packs}`, indent: 1});
        receipt = await cryptoCardsController.setPacksTokenAddress(tokenAddress.packs, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // Distribute Initial GUM Tokens to Gum Controller
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Distributing initial GUM to Reserve Accounts...'});
        receipt = await cryptoCardsGum.distributeInitialGum(_getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // Enable GUM Token Purchases
        //
        if (Lib.network !== 'mainnet') {
            Lib.log({separator: true});
            Lib.log({spacer: true});
            Lib.log({msg: 'Enabling GUM Token Purchases...'});
            receipt = await cryptoCardsGum.enablePurchases(_getTxOptions());
            Lib.logTxResult(receipt);
            totalGas += receipt.receipt.gasUsed;
        }


        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Linking Complete
        Lib.log({separator: true});
        Lib.log({separator: true});

        Lib.log({spacer: true});
        Lib.log({spacer: true});

        Lib.log({msg: `Total Gas Used: ${totalGas} WEI`});
        Lib.log({msg: `Gas Price:      ${Lib.fromWeiToGwei(options.gasPrice)} GWEI`});
        Lib.log({msg: `Actual Cost:    ${Lib.fromWeiToEther(totalGas * options.gasPrice)} ETH`});

        Lib.log({spacer: true});
        Lib.log({msg: 'Token Linking Complete!'});
        process.exit(0);
    }
    catch (err) {
        console.log(err);
        process.exit(1);
    }
};

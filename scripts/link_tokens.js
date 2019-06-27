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

const { Lib } = require('./common');
const { networkOptions, contracts } = require('../config');
const _ = require('lodash');

const CryptoCardsPacks = contracts.getFromLocal('CryptoCardsPacks');
const CryptoCardsCards = contracts.getFromLocal('CryptoCardsCards');
const CryptoCardsGum = contracts.getFromLocal('CryptoCardsGum');
const CryptoCardsGumDistributor = contracts.getFromLocal('CryptoCardsGumDistributor');
const CryptoCardsController = contracts.getFromLocal('CryptoCardsController');

const GUM_REGULAR_FLAVOR = 0;

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
        packs : '0x8a43C333eC0A26e84C4CF5b6338Bf6983eFEBd8D',
        cards : '0xE2E450b20B25311bb135eE7A3d546EEb526ca349',
        gum   : '0xC042CAF4E8d49E8e06Cc61D3B8448b4424Cc6A50'
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

    const inHouseAccount = process.env[`${_.toUpper(Lib.network)}_IN_HOUSE_ACCOUNT`];
    const reserveAccount = process.env[`${_.toUpper(Lib.network)}_RESERVE_ACCOUNT`];
    const bountyAccount = process.env[`${_.toUpper(Lib.network)}_BOUNTY_ACCOUNT`];
    const marketingAccount = process.env[`${_.toUpper(Lib.network)}_MARKETING_ACCOUNT`];
    const airdropAccount = process.env[`${_.toUpper(Lib.network)}_AIRDROP_ACCOUNT`];

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
        const cryptoCardsGum = await Lib.getContractInstance(CryptoCardsGum, ddCryptoCardsGum.address);

        const ddCryptoCardsGumDistributor = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsGumDistributor');
        const cryptoCardsGumDistributor = await Lib.getContractInstance(CryptoCardsGumDistributor, ddCryptoCardsGumDistributor.address);

        const ddCryptoCardsCards = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsCards');
        const cryptoCardsCards = await Lib.getContractInstance(CryptoCardsCards, ddCryptoCardsCards.address);

        const ddCryptoCardsPacks = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsPacks');
        const cryptoCardsPacks = await Lib.getContractInstance(CryptoCardsPacks, ddCryptoCardsPacks.address);

        const ddCryptoCardsController = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsController');
        const cryptoCardsController = await Lib.getContractInstance(CryptoCardsController, ddCryptoCardsController.address);


        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Contract Token Linking

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Assign Distributor of Initial GUM
        Lib.log({spacer: true});
        Lib.log({msg: '-- Assign Distributor of Initial GUM Tokens (ERC20) --'});
        receipt = await cryptoCardsGumDistributor.setGumToken(tokenAddress.gum, _getTxOptions());
        Lib.logTxResult(receipt);

        //
        // CryptoCardsGum
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Gum to Tokens...'});
        Lib.verbose && Lib.log({msg: `CryptoCardsGumToken: ${tokenAddress.gum}`, indent: 1});
        receipt = await cryptoCardsGum.setGumToken(tokenAddress.gum, GUM_REGULAR_FLAVOR, web3.utils.asciiToHex('Regular'), _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;
        Lib.verbose && Lib.log({msg: `CryptoCardsCardToken: ${tokenAddress.cards}`, indent: 1});
        receipt = await cryptoCardsGum.setCardToken(tokenAddress.cards, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({msg: 'Setting Gum per Pack...'});
        Lib.verbose && Lib.log({msg: `setGumPerPack: ${options.gumPerPack}`, indent: 1});
        receipt = await cryptoCardsGum.setGumPerPack(GUM_REGULAR_FLAVOR, options.gumPerPack, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCardsCards
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Cards to Tokens...'});
        Lib.verbose && Lib.log({msg: `CryptoCardsCardToken: ${tokenAddress.cards}`, indent: 1});
        receipt = await cryptoCardsCards.setCryptoCardsCardToken(tokenAddress.cards, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCardPacks
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Packs to Tokens...'});
        Lib.verbose && Lib.log({msg: `CryptoCardsPackToken: ${tokenAddress.packs}`, indent: 1});
        receipt = await cryptoCardsPacks.setCryptoCardsPackToken(tokenAddress.packs, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;
        Lib.verbose && Lib.log({msg: `CryptoCardsCardToken: ${tokenAddress.cards}`, indent: 1});
        receipt = await cryptoCardsPacks.setCryptoCardsCardToken(tokenAddress.cards, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // GUM Initial Accounts
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Updating GUM Initial Accounts...'});
        Lib.verbose && Lib.log({msg: `In-House Account:  ${inHouseAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Reserve Account:   ${reserveAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Bounty Account:    ${bountyAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Marketing Account: ${marketingAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Airdrop Account:   ${airdropAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Gum Contract:      ${cryptoCardsGum.address}`, indent: 1});
        const accounts = [inHouseAccount, reserveAccount, bountyAccount, marketingAccount, airdropAccount, cryptoCardsGum.address];
        receipt = await cryptoCardsGumDistributor.setInitialAccounts(accounts, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;
        Lib.log({spacer: true});

        //
        // Distribute Initial GUM Tokens
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Distributing initial GUM to Reserve Accounts...'});
        receipt = await cryptoCardsGumDistributor.distributeInitialGum(_getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;


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

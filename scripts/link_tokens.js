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
const { networkOptions, tokenAddresses, contracts } = require('../config');
const _ = require('lodash');

const CryptoCardsPacks = contracts.getFromLocal('CryptoCardsPacks');
const CryptoCardsCards = contracts.getFromLocal('CryptoCardsCards');
const CryptoCardsGum = contracts.getFromLocal('CryptoCardsGum');
const CryptoCardsTokenMigrator = contracts.getFromLocal('CryptoCardsTokenMigrator');
const CryptoCardsController = contracts.getFromLocal('CryptoCardsController');

const GWEI_UNIT = 1e9;
const GUM_REGULAR_FLAVOR = 0;

Lib.network = process.env.CCC_NETWORK_NAME;
Lib.networkProvider = process.env.CCC_NETWORK_PROVIDER;
Lib.networkId = process.env.CCC_NETWORK_ID;
Lib.verbose = (process.env.CCC_VERBOSE_LOGS === 'yes');

module.exports = async function() {
    Lib.log({separator: true});
    let nonce = 0;
    let receipt;
    let gasPrice;
    if (_.isUndefined(networkOptions[Lib.network])) {
        Lib.network = 'local';
    }

    const options = networkOptions[Lib.network];
    const owner = process.env[`${_.toUpper(Lib.network)}_OWNER_ACCOUNT`];

    // Get Old Contract Addresses
    const oldAddresses = tokenAddresses[Lib.network];

    // Merge with New Contract Addresses
    const deployedState = Lib.getDeployedAddresses(Lib.networkProvider);
    const contractAddresses = _.assignIn({}, oldAddresses, _.get(deployedState, 'data', {}));

    const inHouseAccount = process.env[`${_.toUpper(Lib.network)}_IN_HOUSE_ACCOUNT`];
    const reserveAccount = process.env[`${_.toUpper(Lib.network)}_RESERVE_ACCOUNT`];
    const bountyAccount = process.env[`${_.toUpper(Lib.network)}_BOUNTY_ACCOUNT`];
    const marketingAccount = process.env[`${_.toUpper(Lib.network)}_MARKETING_ACCOUNT`];
    const airdropAccount = process.env[`${_.toUpper(Lib.network)}_AIRDROP_ACCOUNT`];

    Lib.deployData = require(`../zos.${Lib.networkProvider}.json`);

    const _getCurrentGasPrice = async () => {
        const suggestedWei = await web3.eth.getGasPrice();
        const suggested = Math.floor(suggestedWei / GWEI_UNIT) * GWEI_UNIT;
        const actual = _.clamp(suggested, options.minGasPrice, options.gasPrice);
        return {actual, suggested};
    };
    const _getTxOptions = (currentPrice) => {
        Lib.verbose && Lib.log({msg: `Paying Gas Price: ${Lib.fromWeiToGwei(currentPrice.actual)} GWEI  (${Lib.fromWeiToGwei(currentPrice.suggested)} suggested)`, indent: 2});
        return {from: owner, nonce: nonce++, gasPrice: currentPrice.actual};
    };

    if (Lib.verbose) {
        Lib.log({separator: true});
        Lib.log({msg: `Network:       ${Lib.network}`});
        Lib.log({msg: `Web3:          ${web3.version}`});
        Lib.log({msg: `Max Gas Price: ${Lib.fromWeiToGwei(options.gasPrice)} GWEI`});
        Lib.log({msg: `Owner:         ${owner}`});
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

        const ddCryptoCardsTokenMigrator = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsTokenMigrator');
        const cryptoCardsTokenMigrator = await Lib.getContractInstance(CryptoCardsTokenMigrator, ddCryptoCardsTokenMigrator.address);

        const ddCryptoCardsCards = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsCards');
        const cryptoCardsCards = await Lib.getContractInstance(CryptoCardsCards, ddCryptoCardsCards.address);

        const ddCryptoCardsPacks = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsPacks');
        const cryptoCardsPacks = await Lib.getContractInstance(CryptoCardsPacks, ddCryptoCardsPacks.address);

        const ddCryptoCardsController = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsController');
        const cryptoCardsController = await Lib.getContractInstance(CryptoCardsController, ddCryptoCardsController.address);


        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Contract Token Linking

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        //
        // CryptoCardsTokenMigrator
        //
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Migrator to Tokens...'});
        Lib.verbose && Lib.log({msg: `CryptoCardsGumToken: ${contractAddresses.gumToken}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsTokenMigrator.setGumToken(contractAddresses.gumToken, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        Lib.verbose && Lib.log({msg: `OLD CryptoCardsGumToken: ${contractAddresses.oldGumToken}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsTokenMigrator.setOldGumToken(contractAddresses.oldGumToken, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        Lib.verbose && Lib.log({msg: `CryptoCardsPackToken: ${contractAddresses.packsToken}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsTokenMigrator.setPacksToken(contractAddresses.packsToken, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        Lib.verbose && Lib.log({msg: `OLD CryptoCardPacks (Packs-Controller): ${contractAddresses.oldPacksCtrl}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsTokenMigrator.setOldPacks(contractAddresses.oldPacksCtrl, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        Lib.verbose && Lib.log({msg: `CryptoCardsCardToken: ${contractAddresses.cardsToken}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsTokenMigrator.setCardsToken(contractAddresses.cardsToken, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        Lib.verbose && Lib.log({msg: `OLD CryptoCardsCardToken (Cards-Token): ${contractAddresses.oldCardsToken}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsTokenMigrator.setOldCardsToken(contractAddresses.oldCardsToken, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        Lib.verbose && Lib.log({msg: `OLD CryptoCards (Cards-Controller): ${contractAddresses.oldCardsCtrl}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsTokenMigrator.setOldCards(contractAddresses.oldCardsCtrl, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);

        //
        // CryptoCardsGum
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Gum to Tokens...'});
        Lib.verbose && Lib.log({msg: `CryptoCardsGumToken: ${contractAddresses.gumToken}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsGum.setGumToken(contractAddresses.gumToken, GUM_REGULAR_FLAVOR, web3.utils.asciiToHex('Regular'), _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);

        Lib.log({msg: 'Setting Gum per Pack...'});
        Lib.verbose && Lib.log({msg: `setGumPerPack: ${options.gumPerPack}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsGum.setGumPerPack(GUM_REGULAR_FLAVOR, options.gumPerPack, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);

        //
        // CryptoCardsCards
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Cards to Tokens...'});
        Lib.verbose && Lib.log({msg: `CryptoCardsCardToken: ${contractAddresses.cardsToken}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsCards.setCryptoCardsCardToken(contractAddresses.cardsToken, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);

        //
        // CryptoCardPacks
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Packs to Tokens...'});
        Lib.verbose && Lib.log({msg: `CryptoCardsPackToken: ${contractAddresses.packsToken}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsPacks.setCryptoCardsPackToken(contractAddresses.packsToken, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        Lib.verbose && Lib.log({msg: `CryptoCardsCardToken: ${contractAddresses.cardsToken}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsPacks.setCryptoCardsCardToken(contractAddresses.cardsToken, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);

        //
        // GUM Initial Accounts
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Updating Migrator with Initial Accounts...'});
        Lib.verbose && Lib.log({msg: `Reserve Account:   ${reserveAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `In-House Account:  ${inHouseAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Bounty Account:    ${bountyAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Marketing Account: ${marketingAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Airdrop Account:   ${airdropAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Gum Contract:      ${cryptoCardsGum.address}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        const accounts = [reserveAccount, inHouseAccount, bountyAccount, marketingAccount, airdropAccount, cryptoCardsGum.address];
        receipt = await cryptoCardsTokenMigrator.setInitialAccounts(accounts, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        Lib.log({spacer: true});

        //
        // Distribute Initial GUM Tokens
        //   - Local Only, handled after ERC20 Migration on Ropsten/Mainnet
        //
        if (Lib.network === 'local') {
            Lib.log({separator: true});
            Lib.log({spacer: true});
            Lib.log({msg: 'Distributing initial GUM to Reserve Accounts...'});
            gasPrice = await _getCurrentGasPrice();
            receipt = await cryptoCardsTokenMigrator.distributeInitialGum(_getTxOptions(gasPrice));
            Lib.logTxResult(receipt);
            Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        }

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Linking Complete
        Lib.log({separator: true});
        Lib.log({separator: true});

        Lib.log({spacer: true});
        Lib.log({spacer: true});

        Lib.log({msg: `Total Gas Used: ${Lib.totalGasCosts.gas} WEI`});
        Lib.log({msg: `Total Cost:     ${Lib.totalGasCosts.eth} ETH`});

        Lib.log({spacer: true});
        Lib.log({msg: 'Token Linking Complete!'});
        process.exit(0);
    }
    catch (err) {
        console.log(err);
        process.exit(1);
    }
};

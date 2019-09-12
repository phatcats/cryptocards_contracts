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

const CryptoCardsTreasury = contracts.getFromLocal('CryptoCardsTreasury');
const CryptoCardsOracle = contracts.getFromLocal('CryptoCardsOracle');
const CryptoCardsLib = contracts.getFromLocal('CryptoCardsLib');
const CryptoCardsGum = contracts.getFromLocal('CryptoCardsGum');
const CryptoCardsCards = contracts.getFromLocal('CryptoCardsCards');
const CryptoCardsPacks = contracts.getFromLocal('CryptoCardsPacks');
const CryptoCardsTokenMigrator = contracts.getFromLocal('CryptoCardsTokenMigrator');
const CryptoCardsController = contracts.getFromLocal('CryptoCardsController');

const GWEI_UNIT = 1e9;

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
    const proxyAdmin = process.env[`${_.toUpper(Lib.network)}_PROXY_ADMIN`];
    const owner = process.env[`${_.toUpper(Lib.network)}_OWNER_ACCOUNT`];
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
        const ddCryptoCardsOracle = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsOracle');
        const cryptoCardsOracle = await Lib.getContractInstance(CryptoCardsOracle, ddCryptoCardsOracle.address);

        const ddCryptoCardsTreasury = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsTreasury');
        const cryptoCardsTreasury = await Lib.getContractInstance(CryptoCardsTreasury, ddCryptoCardsTreasury.address);

        const ddCryptoCardsLib = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsLib');
        const cryptoCardsLib = await Lib.getContractInstance(CryptoCardsLib, ddCryptoCardsLib.address);

        const ddCryptoCardsGum = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsGum');
        const cryptoCardsGum = await Lib.getContractInstance(CryptoCardsGum, ddCryptoCardsGum.address);

        const ddCryptoCardsCards = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsCards');
        const cryptoCardsCards = await Lib.getContractInstance(CryptoCardsCards, ddCryptoCardsCards.address);

        const ddCryptoCardsPacks = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsPacks');
        const cryptoCardsPacks = await Lib.getContractInstance(CryptoCardsPacks, ddCryptoCardsPacks.address);

        const ddCryptoCardsTokenMigrator = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsTokenMigrator');
        const cryptoCardsTokenMigrator = await Lib.getContractInstance(CryptoCardsTokenMigrator, ddCryptoCardsTokenMigrator.address);

        const ddCryptoCardsController = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsController');
        const cryptoCardsController = await Lib.getContractInstance(CryptoCardsController, ddCryptoCardsController.address);


        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Store Contract Addresses for other Scripts
        const deployedState = Lib.getDeployedAddresses(Lib.networkProvider);
        deployedState.data.controller = ddCryptoCardsController.address;
        deployedState.data.oracle     = ddCryptoCardsOracle.address;
        deployedState.data.treasury   = ddCryptoCardsTreasury.address;
        deployedState.data.packs      = ddCryptoCardsPacks.address;
        deployedState.data.cards      = ddCryptoCardsCards.address;
        deployedState.data.gum        = ddCryptoCardsGum.address;
        deployedState.data.lib        = ddCryptoCardsLib.address;
        deployedState.data.migrator   = ddCryptoCardsTokenMigrator.address;
        Lib.setDeployedAddresses(deployedState);


        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Contract Initialization

        //
        // CryptoCardsOracle
        //
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Oracle to Contracts...'});
        Lib.verbose && Lib.log({msg: `Controller: ${ddCryptoCardsController.address}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsOracle.setContractController(ddCryptoCardsController.address, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        Lib.verbose && Lib.log({msg: `Packs: ${ddCryptoCardsPacks.address}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsOracle.setPacksAddress(ddCryptoCardsPacks.address, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);

        //
        // CryptoCardsTreasury
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Treasury to Contracts...'});
        Lib.verbose && Lib.log({msg: `Controller: ${ddCryptoCardsController.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `In-House Account: ${inHouseAccount}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsTreasury.setContractAddresses(ddCryptoCardsController.address, inHouseAccount, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);

        //
        // CryptoCardsLib
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Lib to Contracts...'});
        Lib.verbose && Lib.log({msg: `Controller: ${ddCryptoCardsController.address}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsLib.setContractController(ddCryptoCardsController.address, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);

        //
        // CryptoCardsGum
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Gum to Contracts...'});
        Lib.verbose && Lib.log({msg: `Packs: ${ddCryptoCardsPacks.address}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsGum.setPacksAddress(ddCryptoCardsPacks.address, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        Lib.verbose && Lib.log({msg: `Cards: ${ddCryptoCardsCards.address}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsGum.setCardsAddress(ddCryptoCardsCards.address, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);

        //
        // CryptoCardsCards
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Cards to Contracts...'});
        Lib.verbose && Lib.log({msg: `Controller: ${ddCryptoCardsController.address}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsCards.setContractController(ddCryptoCardsController.address, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        Lib.verbose && Lib.log({msg: `Gum: ${ddCryptoCardsGum.address}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsCards.setGumAddress(ddCryptoCardsGum.address, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);

        //
        // CryptoCardsPacks
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Packs to Contracts...'});
        Lib.verbose && Lib.log({msg: `Controller: ${ddCryptoCardsController.address}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsPacks.setContractController(ddCryptoCardsController.address, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        Lib.verbose && Lib.log({msg: `Oracle: ${ddCryptoCardsOracle.address}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsPacks.setOracleAddress(ddCryptoCardsOracle.address, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        Lib.verbose && Lib.log({msg: `Gum: ${ddCryptoCardsGum.address}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsPacks.setGumAddress(ddCryptoCardsGum.address, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        Lib.verbose && Lib.log({msg: `Lib: ${ddCryptoCardsLib.address}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsPacks.setLibAddress(ddCryptoCardsLib.address, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);

        //
        // CryptoCardsController
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Controller to Contracts...'});
        Lib.verbose && Lib.log({msg: `Oracle: ${ddCryptoCardsOracle.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Treasury: ${ddCryptoCardsTreasury.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Cards: ${ddCryptoCardsCards.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Packs: ${ddCryptoCardsPacks.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Lib: ${ddCryptoCardsLib.address}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsController.setContractAddresses(
            ddCryptoCardsOracle.address,
            ddCryptoCardsCards.address,
            ddCryptoCardsPacks.address,
            ddCryptoCardsTreasury.address,
            ddCryptoCardsLib.address,
            _getTxOptions(gasPrice)
        );
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);

        //
        // Oracle API Endpoint
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Updating Oracle API Endpoint...'});
        Lib.verbose && Lib.log({msg: `API Endpoint: ${options.oracleApiEndpoint}`, indent: 1});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsOracle.updateApiEndpoint(options.oracleApiEndpoint, _getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);

        //
        // Pause the Controller
        //
        if (Lib.network === 'mainnet') {
            Lib.log({separator: true});
            Lib.log({spacer: true});
            Lib.log({msg: 'Pausing Controller...'});
            gasPrice = await _getCurrentGasPrice();
            receipt = await cryptoCardsController.pause(_getTxOptions(gasPrice));
            Lib.logTxResult(receipt);
            Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        }

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Deploy Complete
        Lib.log({separator: true});
        Lib.log({separator: true});

        Lib.log({spacer: true});
        Lib.log({spacer: true});

        Lib.log({msg: 'Contract Addresses:'});
        Lib.log({msg: `Controller:      ${ddCryptoCardsController.address}`, indent: 1});
        Lib.log({msg: `Treasury:        ${ddCryptoCardsTreasury.address}`, indent: 1});
        Lib.log({msg: `Oracle:          ${ddCryptoCardsOracle.address}`, indent: 1});
        Lib.log({msg: `Packs:           ${ddCryptoCardsPacks.address}`, indent: 1});
        Lib.log({msg: `Cards:           ${ddCryptoCardsCards.address}`, indent: 1});
        Lib.log({msg: `Gum:             ${ddCryptoCardsGum.address}`, indent: 1});
        Lib.log({msg: `Token Migrator:  ${ddCryptoCardsTokenMigrator.address}`, indent: 1});
        Lib.log({msg: `Lib:             ${ddCryptoCardsLib.address}`, indent: 1});
        Lib.log({spacer: true});
        Lib.log({msg: 'Accounts:'});
        Lib.log({msg: `Proxy Admin:     ${proxyAdmin}`, indent: 1});
        Lib.log({msg: `Owner:           ${owner}`, indent: 1});
        Lib.log({msg: `In-House:        ${inHouseAccount}`, indent: 1});
        Lib.log({msg: `Reserve:         ${reserveAccount}`, indent: 1});
        Lib.log({msg: `Bounty:          ${bountyAccount}`, indent: 1});
        Lib.log({msg: `Marketing:       ${marketingAccount}`, indent: 1});
        Lib.log({msg: `Airdrop:         ${airdropAccount}`, indent: 1});
        Lib.log({spacer: true});
        Lib.log({msg: `Total Gas Used:  ${Lib.totalGasCosts.gas} WEI`});
        Lib.log({msg: `Total Cost:      ${Lib.totalGasCosts.eth} ETH`});

        Lib.log({spacer: true});
        Lib.log({msg: 'Initializations Complete!'});
        process.exit(0);
    }
    catch (err) {
        console.log(err);
        process.exit(1);
    }
};

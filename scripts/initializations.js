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


module.exports = async function() {
    Lib.log({separator: true});
    let nonce = 0;
    let totalGas = 0;
    let receipt;
    if (_.isUndefined(networkOptions[Lib.network])) {
        Lib.network = 'local';
    }

    const options = networkOptions[Lib.network];
    const proxyAdmin = process.env[`${_.toUpper(Lib.network)}_PROXY_ADMIN`];
    const owner = process.env[`${_.toUpper(Lib.network)}_OWNER_ACCOUNT`];
    const inHouseAccount = process.env[`${_.toUpper(Lib.network)}_IN_HOUSE_ACCOUNT`];
    const bountyAccount = process.env[`${_.toUpper(Lib.network)}_BOUNTY_ACCOUNT`];
    const marketingAccount = process.env[`${_.toUpper(Lib.network)}_MARKETING_ACCOUNT`];
    const exchangeAccount = process.env[`${_.toUpper(Lib.network)}_EXCHANGE_ACCOUNT`];

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
        const ddCryptoCardsOracle = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsOracle');
        const cryptoCardsOracle = Lib.getContractInstance(CryptoCardsOracle, ddCryptoCardsOracle.address);

        const ddCryptoCardsTreasury = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsTreasury');
        const cryptoCardsTreasury = Lib.getContractInstance(CryptoCardsTreasury, ddCryptoCardsTreasury.address);

        const ddCryptoCardsLib = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsLib');
        const cryptoCardsLib = Lib.getContractInstance(CryptoCardsLib, ddCryptoCardsLib.address);

        const ddCryptoCardsGum = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsGum');
        const cryptoCardsGum = Lib.getContractInstance(CryptoCardsGum, ddCryptoCardsGum.address);

        const ddCryptoCards = Lib.getDeployDataFor('cryptocardscontracts/CryptoCards');
        const cryptoCards = Lib.getContractInstance(CryptoCards, ddCryptoCards.address);

        const ddCryptoCardPacks = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardPacks');
        const cryptoCardPacks = Lib.getContractInstance(CryptoCardPacks, ddCryptoCardPacks.address);

        const ddCryptoCardsController = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsController');
        const cryptoCardsController = Lib.getContractInstance(CryptoCardsController, ddCryptoCardsController.address);


        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Contract Initialization

        //
        // CryptoCardsOracle
        //
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Oracle to Contracts...'});
        Lib.verbose && Lib.log({msg: `Controller: ${ddCryptoCardsController.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Packs: ${ddCryptoCardPacks.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Lib: ${ddCryptoCardsLib.address}`, indent: 1});
        receipt = await cryptoCardsOracle.setContractAddresses(
            ddCryptoCardsController.address,
            ddCryptoCardPacks.address,
            ddCryptoCardsLib.address,
            _getTxOptions()
        );
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCardsTreasury
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Treasury to Contracts...'});
        Lib.verbose && Lib.log({msg: `Controller: ${ddCryptoCardsController.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `In-House Account: ${inHouseAccount}`, indent: 1});
        receipt = await cryptoCardsTreasury.setContractAddresses(
            ddCryptoCardsController.address,
            inHouseAccount,
            _getTxOptions()
        );
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCardsGum
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Gum to Packs...'});
        Lib.verbose && Lib.log({msg: `Packs: ${ddCryptoCardPacks.address}`, indent: 1});
        receipt = await cryptoCardsGum.setPacksAddress(
            ddCryptoCardPacks.address,
            _getTxOptions()
        );
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCards
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Cards to Contracts...'});
        Lib.verbose && Lib.log({msg: `Controller: ${ddCryptoCardsController.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Packs: ${ddCryptoCardPacks.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Lib: ${ddCryptoCardsLib.address}`, indent: 1});
        receipt = await cryptoCards.setContractAddresses(
            ddCryptoCardsController.address,
            ddCryptoCardPacks.address,
            ddCryptoCardsLib.address,
            _getTxOptions()
        );
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCardPacks
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Packs to Contracts...'});
        Lib.verbose && Lib.log({msg: `Controller: ${ddCryptoCardsController.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Oracle: ${ddCryptoCardsOracle.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Cards: ${ddCryptoCards.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Gum: ${ddCryptoCardsGum.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Lib: ${ddCryptoCardsLib.address}`, indent: 1});
        receipt = await cryptoCardPacks.setContractAddresses(
            ddCryptoCardsController.address,
            ddCryptoCardsOracle.address,
            ddCryptoCards.address,
            ddCryptoCardsGum.address,
            ddCryptoCardsLib.address,
            _getTxOptions()
        );
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCardsController
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Controller to Contracts...'});
        Lib.verbose && Lib.log({msg: `Oracle: ${ddCryptoCardsOracle.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Cards: ${ddCryptoCards.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Packs: ${ddCryptoCardPacks.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Treasury: ${ddCryptoCardsTreasury.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Gum: ${ddCryptoCardsGum.address}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Lib: ${ddCryptoCardsLib.address}`, indent: 1});
        receipt = await cryptoCardsController.setContractAddresses(
            ddCryptoCardsOracle.address,
            ddCryptoCards.address,
            ddCryptoCardPacks.address,
            ddCryptoCardsTreasury.address,
            ddCryptoCardsGum.address,
            ddCryptoCardsLib.address,
            _getTxOptions()
        );
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // Oracle API Endpoint
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Updating Oracle API Endpoint...'});
        Lib.verbose && Lib.log({msg: `API Endpoint: ${options.oracleApiEndpoint}`, indent: 1});
        receipt = await cryptoCardsOracle.updateApiEndpoint(options.oracleApiEndpoint, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // GUM Reserve Accounts
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Updating GUM Reserve Accounts...'});
        Lib.verbose && Lib.log({msg: `In-House Account:  ${inHouseAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Bounty Account:    ${bountyAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Marketing Account: ${marketingAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Exchange Account:  ${exchangeAccount}`, indent: 1});
        const accounts = [inHouseAccount, bountyAccount, marketingAccount, exchangeAccount];
        receipt = await cryptoCardsGum.setReserveAccounts(accounts, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;
        Lib.log({spacer: true});

        //
        // Pause the Controller
        //
        if (Lib.network === 'mainnet') {
            Lib.log({separator: true});
            Lib.log({spacer: true});
            Lib.log({msg: 'Pausing Controller...'});
            receipt = await cryptoCardsController.pause(_getTxOptions());
            Lib.logTxResult(receipt);
            totalGas += receipt.receipt.gasUsed;
        }

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Deploy Complete
        Lib.log({separator: true});
        Lib.log({separator: true});

        Lib.log({spacer: true});
        Lib.log({spacer: true});

        Lib.log({msg: 'Contract Addresses:'});
        Lib.log({msg: `Controller:  ${ddCryptoCardsController.address}`, indent: 1});
        Lib.log({msg: `Treasury:    ${ddCryptoCardsTreasury.address}`, indent: 1});
        Lib.log({msg: `Oracle:      ${ddCryptoCardsOracle.address}`, indent: 1});
        Lib.log({msg: `Packs:       ${ddCryptoCardPacks.address}`, indent: 1});
        Lib.log({msg: `Cards:       ${ddCryptoCards.address}`, indent: 1});
        Lib.log({msg: `Gum:         ${ddCryptoCardsGum.address}`, indent: 1});
        Lib.log({msg: `Lib:         ${ddCryptoCardsLib.address}`, indent: 1});
        Lib.log({spacer: true});
        Lib.log({msg: 'Accounts:'});
        Lib.log({msg: `Proxy Admin: ${proxyAdmin}`, indent: 1});
        Lib.log({msg: `Owner:       ${owner}`, indent: 1});
        Lib.log({msg: `In-House:    ${inHouseAccount}`, indent: 1});
        Lib.log({msg: `Bounty:      ${bountyAccount}`, indent: 1});
        Lib.log({msg: `Marketing:   ${marketingAccount}`, indent: 1});
        Lib.log({msg: `Exchange:    ${exchangeAccount}`, indent: 1});
        Lib.log({spacer: true});
        Lib.log({msg: `Total Gas Used: ${totalGas} WEI`});
        Lib.log({msg: `Gas Price:      ${Lib.fromWeiToGwei(options.gasPrice)} GWEI`});
        Lib.log({msg: `Actual Cost:    ${Lib.fromWeiToEther(totalGas * options.gasPrice)} ETH`});

        Lib.log({spacer: true});
        Lib.log({msg: 'Initializations Complete!'});
        process.exit(0);
    }
    catch (err) {
        console.log(err);
        process.exit(1);
    }
};

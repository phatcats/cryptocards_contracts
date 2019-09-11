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

const GUM_REGULAR_FLAVOR = 0;

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
    const owner = process.env[`${_.toUpper(Lib.network)}_OWNER_ACCOUNT`];
    const tokenAddress = tokenAddresses[Lib.network];

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
        Lib.verbose && Lib.log({msg: `CryptoCardsGumToken: ${tokenAddress.gumToken}`, indent: 1});
        receipt = await cryptoCardsTokenMigrator.setGumToken(tokenAddress.gumToken, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;
        Lib.verbose && Lib.log({msg: `OLD CryptoCardsGumToken: ${tokenAddress.oldGumToken}`, indent: 1});
        receipt = await cryptoCardsTokenMigrator.setOldGumToken(tokenAddress.oldGumToken, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;
        Lib.verbose && Lib.log({msg: `CryptoCardsPackToken: ${tokenAddress.packsToken}`, indent: 1});
        receipt = await cryptoCardsTokenMigrator.setPacksToken(tokenAddress.packsToken, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;
        Lib.verbose && Lib.log({msg: `OLD CryptoCardPacks (Packs-Controller): ${tokenAddress.oldPacksCtrl}`, indent: 1});
        receipt = await cryptoCardsTokenMigrator.setOldPacks(tokenAddress.oldPacksCtrl, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;
        Lib.verbose && Lib.log({msg: `CryptoCardsCardToken: ${tokenAddress.cardsToken}`, indent: 1});
        receipt = await cryptoCardsTokenMigrator.setCardsToken(tokenAddress.cardsToken, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;
        Lib.verbose && Lib.log({msg: `OLD CryptoCardsCardToken (Cards-Token): ${tokenAddress.oldCardsToken}`, indent: 1});
        receipt = await cryptoCardsTokenMigrator.setOldCardsToken(tokenAddress.oldCardsToken, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;
        Lib.verbose && Lib.log({msg: `OLD CryptoCards (Cards-Controller): ${tokenAddress.oldCardsCtrl}`, indent: 1});
        receipt = await cryptoCardsTokenMigrator.setOldCards(tokenAddress.oldCardsCtrl, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCardsGum
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Gum to Tokens...'});
        Lib.verbose && Lib.log({msg: `CryptoCardsGumToken: ${tokenAddress.gumToken}`, indent: 1});
        receipt = await cryptoCardsGum.setGumToken(tokenAddress.gumToken, GUM_REGULAR_FLAVOR, web3.utils.asciiToHex('Regular'), _getTxOptions());
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
        Lib.verbose && Lib.log({msg: `CryptoCardsCardToken: ${tokenAddress.cardsToken}`, indent: 1});
        receipt = await cryptoCardsCards.setCryptoCardsCardToken(tokenAddress.cardsToken, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCardPacks
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Packs to Tokens...'});
        Lib.verbose && Lib.log({msg: `CryptoCardsPackToken: ${tokenAddress.packsToken}`, indent: 1});
        receipt = await cryptoCardsPacks.setCryptoCardsPackToken(tokenAddress.packsToken, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;
        Lib.verbose && Lib.log({msg: `CryptoCardsCardToken: ${tokenAddress.cardsToken}`, indent: 1});
        receipt = await cryptoCardsPacks.setCryptoCardsCardToken(tokenAddress.cardsToken, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

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
        const accounts = [reserveAccount, inHouseAccount, bountyAccount, marketingAccount, airdropAccount, cryptoCardsGum.address];
        receipt = await cryptoCardsTokenMigrator.setInitialAccounts(accounts, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;
        Lib.log({spacer: true});

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

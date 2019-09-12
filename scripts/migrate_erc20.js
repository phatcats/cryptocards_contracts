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
const { networkOptions, migrationAccounts, contracts } = require('../config');
const _ = require('lodash');

const ETH_UNIT = web3.utils.toBN(1e18);
const GWEI_UNIT = 1e9;

const CryptoCardsTokenMigrator = contracts.getFromLocal('CryptoCardsTokenMigrator');

Lib.network = process.env.CCC_NETWORK_NAME;
Lib.networkProvider = process.env.CCC_NETWORK_PROVIDER;
Lib.networkId = process.env.CCC_NETWORK_ID;
Lib.verbose = (process.env.CCC_VERBOSE_LOGS === 'yes');

module.exports = async function() {
    Lib.log({separator: true});
    let nonce = 0;
    let receipt;
    if (_.isUndefined(networkOptions[Lib.network])) {
        Lib.network = 'local';
    }

    const options = networkOptions[Lib.network];
    const owner = process.env[`${_.toUpper(Lib.network)}_OWNER_ACCOUNT`];
    const accountsToMigrate = migrationAccounts[Lib.network];

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
        const ddCryptoCardsTokenMigrator = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsTokenMigrator');
        const cryptoCardsTokenMigrator = await Lib.getContractInstance(CryptoCardsTokenMigrator, ddCryptoCardsTokenMigrator.address);


        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Contract Token Migration

        //
        // Migrate GUM (ERC20) Tokens
        //
        let account;
        let oldAmount;
        let newAmount;
        let gasPrice;
        for (let i = 0; i < accountsToMigrate.erc20.length; i++) {
            account = accountsToMigrate.erc20[i];

            Lib.log({separator: true});
            Lib.log({spacer: true});
            Lib.log({msg: `Migrating GUM for Token Holder "${account}"...`});
            gasPrice = await _getCurrentGasPrice();
            receipt = await cryptoCardsTokenMigrator.migrateTokenHolder(account, _getTxOptions(gasPrice));
            oldAmount = web3.utils.toBN(receipt.logs[0].args.oldAmount).toString();
            newAmount = web3.utils.toBN(receipt.logs[0].args.newAmount).div(ETH_UNIT).toString();
            Lib.verbose && Lib.log({msg: ` - Migrated ${oldAmount} Old Tokens for ${newAmount} New Tokens`, indent: 1});
            Lib.logTxResult(receipt);
            Lib.trackTotalGasCosts(receipt, gasPrice.actual);
        }

        //
        // Distribute Initial GUM Tokens
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Distributing initial GUM to Reserve Accounts...'});
        gasPrice = await _getCurrentGasPrice();
        receipt = await cryptoCardsTokenMigrator.distributeInitialGum(_getTxOptions(gasPrice));
        Lib.logTxResult(receipt);
        Lib.trackTotalGasCosts(receipt, gasPrice.actual);

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // ERC20 Migration Complete
        Lib.log({separator: true});
        Lib.log({separator: true});

        Lib.log({spacer: true});
        Lib.log({spacer: true});

        Lib.log({msg: `Total Gas Used: ${Lib.totalGasCosts.gas} WEI`});
        Lib.log({msg: `Total Cost:     ${Lib.totalGasCosts.eth} ETH`});

        Lib.log({spacer: true});
        Lib.log({msg: 'ERC20 Token Migration Complete!'});
        process.exit(0);
    }
    catch (err) {
        console.log(err);
        process.exit(1);
    }
};

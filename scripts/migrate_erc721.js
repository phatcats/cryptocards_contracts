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

const fs = require('fs');
const { Lib } = require('./common');
const {
    networkOptions,
    migrationPhase,
    migrationAccounts,
    contracts
} = require('../config');
const _ = require('lodash');
const bigint = require('big-integer');

const NUM_BASE = 10;
const HEX_BASE = 16;
const GWEI_UNIT = 1e9;
const GUM_PER_CARD = [15, 30];

const _migrationState = {
    filename: '',
    data: {}
};

const CryptoCardsLib = contracts.getFromLocal('CryptoCardsLib');
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

    const deployedState = Lib.getDeployedAddresses(Lib.networkProvider);
    const contractAddresses = _.get(deployedState, 'data', {});

    _migrationState.filename = `../migration-state-${Lib.network}.json`;
    _readMigrationStateFile();

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
        const ddCryptoCardsLib = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsLib');
        const cryptoCardsLib = await Lib.getContractInstance(CryptoCardsLib, ddCryptoCardsLib.address);

        const ddCryptoCardsTokenMigrator = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsTokenMigrator');
        const cryptoCardsTokenMigrator = await Lib.getContractInstance(CryptoCardsTokenMigrator, ddCryptoCardsTokenMigrator.address);


        const _convertOldCardToNewCard = async (oldCardHash, base = HEX_BASE) => {
            let rank = _readBits(oldCardHash, 22, 8);
            let issue = _readBits(oldCardHash, 0, 22);
            const gum = _.random(GUM_PER_CARD[0], GUM_PER_CARD[1]);
            const newTokenData = {year: 0, gen: 0, rank, issue, gum, eth: 0};
            return _packCardBits(newTokenData, base);
        };

        const _convertOldCardsToNewCards = async (oldCards, serialize = false) => {
            if (_.isString(oldCards)) { oldCards = oldCards.split('.'); }
            if (!_.isArray(oldCards)) { oldCards = [oldCards]; }

            const newCards = [];
            for (let i = 0; i < oldCards.length; i++) {
                newCards.push(await _convertOldCardToNewCard(oldCards[i]));
            }

            if (serialize) {
                return newCards.join('.');
            }
            return newCards;
        };

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Contract Token Migration

        let account;
        let gasPrice;
        let response;
        let tokenCount;
        let oldTokenId;
        let newTokenId;
        let oldHash;
        let newHash;
        let receipt;
        let txReceipt;
        let tokenIndex;
        let batchPass;
        let batchTokenIds;
        let isFrozen;
        let toBeMigrated;
        let migrationState;

        //
        // Migrate Pack (ERC721) Tokens
        //
        if (migrationPhase.migratePacks) {
            Lib.log({msg: `Pack Token Holders: ${accountsToMigrate.erc721.length}`});
            for (let i = 0; i < accountsToMigrate.erc721.length; i++) {
                account = accountsToMigrate.erc721[i];
                batchPass = _getBatchPass({type: 'packs', account});
                tokenIndex = batchPass * migrationPhase.batchSize;

                Lib.log({separator: true});
                Lib.log({spacer: true});
                Lib.log({msg: `Get Packs for Token Holder "${account}"...`});
                response = await cryptoCardsTokenMigrator.packsBalanceOf(account);
                tokenCount = web3.utils.toBN(response).toNumber();

                if (tokenCount < 1) {
                    Lib.log({msg: `No Packs found, skipping...`});
                    continue;
                }
                if (tokenIndex >= tokenCount) {
                    Lib.log({msg: `All Packs migrated, skipping...`});
                    continue;
                }

                toBeMigrated = Math.min(migrationPhase.batchSize, tokenCount - tokenIndex);
                Lib.log({msg: `Found ${tokenCount} Packs to be migrated.  Migrating ${toBeMigrated} Packs starting at ${tokenIndex}...`});

                batchTokenIds = [];
                for (; tokenIndex < tokenCount && batchTokenIds.length < migrationPhase.batchSize; tokenIndex++) {
                    Lib.log({spacer: true});
                    Lib.log({separator: true});

                    // Get Old Pack Token ID
                    response = await cryptoCardsTokenMigrator.packsTokenOfOwnerByIndex(account, tokenIndex);
                    oldTokenId = web3.utils.toBN(response).toString();

                    // Skip Previously Migrated Packs
                    migrationState = {type: 'packs', tokenId: oldTokenId};
                    if (_hasMigratedToken(migrationState)) {
                        Lib.verbose && Lib.log({msg: `Skipping Previously Migrated Token "${oldTokenId}"...`, indent: 1});
                        continue;
                    }
                    _markMigrated(migrationState);

                    // Skip Opened Packs
                    isFrozen = await cryptoCardsTokenMigrator.isTokenFrozen(oldTokenId);
                    if (isFrozen) {
                        Lib.verbose && Lib.log({msg: `Skipping Opened Pack Token "${oldTokenId}"...`, indent: 1});
                        continue;
                    }

                    // Get Hash of Cards in Pack
                    oldHash = await cryptoCardsTokenMigrator.packHashById(oldTokenId);

                    // Convert Old Card TokenIDs to New Card TokenIDs
                    newHash = await _convertOldCardsToNewCards(oldHash, true);

                    // Mint New Pack with New Cards
                    Lib.verbose && Lib.log({msg: `Minting Pack...`, indent: 1});
                    Lib.verbose && Lib.log({msg: `Old Token ID: "${oldTokenId}"`, indent: 2});
                    Lib.verbose && Lib.log({msg: `Old Pack-Hash: "${oldHash}"`, indent: 2});
                    Lib.verbose && Lib.log({msg: `New Pack-Hash: "${newHash}"`, indent: 2});
                    gasPrice = await _getCurrentGasPrice();
                    receipt = await cryptoCardsTokenMigrator.mintNewPack(account, `0.${newHash}`, _getTxOptions(gasPrice));
                    txReceipt = await web3.eth.getTransactionReceipt(receipt.tx);

                    // Get Token ID from "Transfer" event; logs[].topics["fnSig", "from", "to", "tokenId"]
                    newTokenId = web3.utils.toBN(txReceipt.logs[0].topics[3]).toString(10);
                    batchTokenIds.push(newTokenId);

                    // Logs
                    Lib.verbose && Lib.log({msg: `Migrated [Pack] Old-Token "${oldTokenId}" for New-Token "${newTokenId}"`, indent: 1});
                    Lib.logTxResult(receipt);
                    Lib.trackTotalGasCosts(receipt, gasPrice.actual);
                    _writeMigrationStateFile();
                }
                _setBatchPass({type: 'packs', account, batchPass: batchPass + 1});
                _writeMigrationStateFile();
            }
        }

        //
        // Migrate Card (ERC721) Tokens
        //
        if (migrationPhase.migrateCards) {
            Lib.log({msg: `Card Token Holders: ${accountsToMigrate.erc721.length}`});
            for (let i = 0; i < accountsToMigrate.erc721.length; i++) {
                account = accountsToMigrate.erc721[i];
                batchPass = _getBatchPass({type: 'cards', account});
                tokenIndex = batchPass * migrationPhase.batchSize;

                Lib.log({separator: true});
                Lib.log({spacer: true});
                Lib.log({msg: `Get Cards for Token Holder "${account}"...`});
                response = await cryptoCardsTokenMigrator.cardsBalanceOf(account);
                tokenCount = web3.utils.toBN(response).toNumber();

                if (tokenCount < 1) {
                    Lib.log({msg: `No Cards found, skipping...`});
                    continue;
                }
                if (tokenIndex >= tokenCount) {
                    Lib.log({msg: `All Cards migrated, skipping...`});
                    continue;
                }

                toBeMigrated = Math.min(migrationPhase.batchSize, tokenCount - tokenIndex);
                Lib.log({msg: `Found ${tokenCount} Cards to be migrated.  Migrating ${toBeMigrated} Cards starting at ${tokenIndex}...`});

                batchTokenIds = [];
                for (; tokenIndex < tokenCount && batchTokenIds.length < migrationPhase.batchSize; tokenIndex++) {
                    // Get Old Card Token ID
                    response = await cryptoCardsTokenMigrator.cardsTokenOfOwnerByIndex(account, tokenIndex);
                    oldTokenId = web3.utils.toBN(response).toString();

                    // Skip Previously Migrated Cards
                    migrationState = {type: 'cards', tokenId: oldTokenId};
                    if (_hasMigratedToken(migrationState)) {
                        Lib.verbose && Lib.log({msg: `Skipping Previously Migrated Token "${oldTokenId}"...`, indent: 1});
                        continue;
                    }
                    _markMigrated(migrationState);

                    // Get Card-Hash for Card
                    oldHash = await cryptoCardsTokenMigrator.cardHashById(oldTokenId);

                    // Convert Old Card into New Card
                    newTokenId = await _convertOldCardToNewCard(oldHash, NUM_BASE);
                    batchTokenIds.push(newTokenId);

                    Lib.verbose && Lib.log({msg: `Adding New Card "${newTokenId}" from Old Card "${oldTokenId} (${oldHash})"...`, indent: 1});
                }
                if (!batchTokenIds.length) {
                    Lib.log({msg: `No Cards left to be migrated, skipping...`});
                    continue;
                }
                Lib.verbose && Lib.log({msg: `Migrating ${batchTokenIds.length} of ${tokenCount} Old Card-Tokens...`, indent: 1});

                // Mint New Cards
                Lib.verbose && Lib.log({msg: `Minting ${batchTokenIds.length} Cards...`, indent: 1});
                gasPrice = await _getCurrentGasPrice();
                receipt = await cryptoCardsTokenMigrator.mintNewCards(account, batchTokenIds, _getTxOptions(gasPrice));
                Lib.verbose && Lib.log({msg: `Successfully migrated ${batchTokenIds.length} Old Card-Tokens!`, indent: 1});
                Lib.logTxResult(receipt);
                Lib.trackTotalGasCosts(receipt, gasPrice.actual);
                _setBatchPass({type: 'cards', account, batchPass: batchPass + 1});
                _writeMigrationStateFile();
            }
        }

        if (migrationPhase.migratePurchasedPacks) {
            // Lib: Set Controller to Owner Account
            Lib.log({separator: true});
            Lib.log({spacer: true});
            Lib.log({msg: 'Linking Lib to Owner as Controller...'});
            Lib.verbose && Lib.log({msg: `Owner: ${owner}`, indent: 1});
            gasPrice = await _getCurrentGasPrice();
            receipt = await cryptoCardsLib.setContractController(owner, _getTxOptions(gasPrice));
            Lib.logTxResult(receipt);
            Lib.trackTotalGasCosts(receipt, gasPrice.actual);

            // Lib: Increment Purchased Pack Count for each Account
            Lib.log({separator: true});
            Lib.log({spacer: true});
            Lib.log({msg: `# of Pack Purchasers: ${accountsToMigrate.packPurchasers.length}`});
            for (let i = 0; i < accountsToMigrate.packPurchasers.length; i++) {
                account = accountsToMigrate.packPurchasers[i].account;
                tokenCount = accountsToMigrate.packPurchasers[i].count;

                Lib.verbose && Lib.log({spacer: true});
                Lib.verbose && Lib.log({msg: `Updating Pack Purchases for "${account}"`, indent: 1});
                gasPrice = await _getCurrentGasPrice();
                receipt = await cryptoCardsLib.incrementPurchasedPackCount(account, tokenCount, _getTxOptions(gasPrice));
                Lib.logTxResult(receipt);
                Lib.trackTotalGasCosts(receipt, gasPrice.actual);
            }

            // Lib: Set Controller back to Controller Contract
            Lib.log({separator: true});
            Lib.log({spacer: true});
            Lib.log({msg: 'Linking Lib to Controller Contract...'});
            Lib.verbose && Lib.log({msg: `Controller: ${contractAddresses.controller}`, indent: 1});
            gasPrice = await _getCurrentGasPrice();
            receipt = await cryptoCardsLib.setContractController(contractAddresses.controller, _getTxOptions(gasPrice));
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
        Lib.log({msg: 'ERC721 Token Migration Complete!'});
        process.exit(0);
    }
    catch (err) {
        console.log(err);
        process.exit(1);
    }
};

const _readMigrationStateFile = () => {
    if (!fs.existsSync(_migrationState.filename)) {
        _writeMigrationStateFile();
    }
    _migrationState.data = JSON.parse(fs.readFileSync(_migrationState.filename, 'utf-8') || '{}');
};

const _writeMigrationStateFile = () => {
    fs.writeFileSync(_migrationState.filename, JSON.stringify(_migrationState.data));
};

const _getBatchPass = ({type, account}) => {
    return _.get(_migrationState.data, `${type}.${account}.batchPass`, 0);
};

const _setBatchPass = ({type, account, batchPass}) => {
    _migrationState.data[type] = _migrationState.data[type] || {};
    _migrationState.data[type][account] = {batchPass};
};

const _markMigrated = ({type, tokenId}) => {
    _migrationState.data[type] = _migrationState.data[type] || {};
    _migrationState.data[type][tokenId] = {migrated: true};
};

const _hasMigratedToken = ({type, tokenId}) => {
    return _.get(_migrationState.data, `${type}.${tokenId}.migrated`, false);
};

const _readBits = (num, from, len) => {
    const mask = ((bigint(1).shiftLeft(len)).minus(1)).shiftLeft(from);
    return bigint(num, HEX_BASE).and(mask).shiftRight(from).toJSNumber();
};

function _packCardBits({year, gen, rank, issue, gum, eth}, base = HEX_BASE) {
    //
    // From Solidity Contract:
    //      (bits[0] | (bits[1] << 4) | (bits[2] << 10) | (bits[3] << 20) | (bits[4] << 32) | (bits[5] << 42);
    //
    let cardInt = bigint(year);
    cardInt = cardInt.or(bigint(gen).shiftLeft(4));
    cardInt = cardInt.or(bigint(rank).shiftLeft(10));
    cardInt = cardInt.or(bigint(issue).shiftLeft(20));
    cardInt = cardInt.or(bigint(gum).shiftLeft(32));
    cardInt = cardInt.or(bigint(eth).shiftLeft(42));

    let packedCard = cardInt.toString(base);
    if (base === HEX_BASE && packedCard.length % 2 !== 0) { // length must be even
        packedCard = `0${packedCard}`;
    }
    return packedCard;
}

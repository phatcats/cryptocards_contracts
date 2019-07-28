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
const bigint = require('big-integer');

const ETH_UNIT = web3.utils.toBN(1e18);
const GUM_PER_CARD = [15, 30];

const MIGRATE_PACKS = false;
const MIGRATE_CARDS = false;
const MAX_MIGRATE_CARDS = 10;

const CryptoCardsTokenMigrator = contracts.getFromLocal('CryptoCardsTokenMigrator');

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
    const accountsToMigrate = migrationAccounts[Lib.network];

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
        const ddCryptoCardsTokenMigrator = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsTokenMigrator');
        const cryptoCardsTokenMigrator = await Lib.getContractInstance(CryptoCardsTokenMigrator, ddCryptoCardsTokenMigrator.address);

        const _convertOldCardToNewCard = async (oldCardHash) => {
            const oldCardData = web3.utils.toBN(oldCardHash);

            let rank = await cryptoCardsTokenMigrator.cardRankFromHash(oldCardData);
            rank = rank.toNumber();

            let issue = await cryptoCardsTokenMigrator.cardIssueFromHash(oldCardData);
            issue = issue.toNumber();

            const gum = _.random(GUM_PER_CARD[0], GUM_PER_CARD[1]);
            const newTokenData = {year: 0, gen: 0, rank, issue, gum, eth: 0};
            return _packCardBits(newTokenData);
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
        let response;
        let tokenCount;
        let oldTokenId;
        let newTokenId;
        let oldHash;
        let newHash;
        let txReceipt;
        let tokenIndex;
        let batchPass;
        let batchTokenIds;
        let isFrozen;
        let toBeMigrated;

        //
        // Migrate Pack (ERC721) Tokens
        //
        if (MIGRATE_PACKS) {
            Lib.log({msg: `Pack Token Holders: ${accountsToMigrate.erc721.length}`});
            for (let i = 0; i < accountsToMigrate.erc721.length; i++) {
                account = accountsToMigrate.erc721[i];

                Lib.log({separator: true});
                Lib.log({spacer: true});
                Lib.log({msg: `Get Packs for Token Holder "${account}"...`});
                response = await cryptoCardsTokenMigrator.packsBalanceOf(account);
                tokenCount = web3.utils.toBN(response).toNumber();
                Lib.verbose && Lib.log({msg: `Migrating ${tokenCount} Old Pack-Tokens...`, indent: 1});

                for (tokenIndex = 0; tokenIndex < tokenCount; tokenIndex++) {
                    Lib.log({spacer: true});
                    Lib.log({separator: true});

                    // Get Old Pack Token ID
                    response = await cryptoCardsTokenMigrator.packsTokenOfOwnerByIndex(account, tokenIndex);
                    oldTokenId = web3.utils.toBN(response).toString();

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
                    receipt = await cryptoCardsTokenMigrator.mintNewPack(account, `0.${newHash}`, _getTxOptions());
                    txReceipt = await web3.eth.getTransactionReceipt(receipt.tx);

                    // Get Token ID from "Transfer" event; logs[].topics["fnSig", "from", "to", "tokenId"]
                    newTokenId = web3.utils.toBN(txReceipt.logs[0].topics[3]).toString(10);

                    // Logs
                    Lib.verbose && Lib.log({msg: `Migrated [Pack] Old-Token "${oldTokenId}" for New-Token "${newTokenId}"`, indent: 1});
                    Lib.verbose && Lib.log({msg: `Old Pack-Hash: "${oldHash}"`, indent: 2});
                    Lib.verbose && Lib.log({msg: `New Pack-Hash: "${newHash}"`, indent: 2});
                    Lib.logTxResult(receipt);
                    totalGas += receipt.receipt.gasUsed;
                }
            }
        }

        //
        // Migrate Card (ERC721) Tokens
        //
        if (MIGRATE_CARDS) {
            Lib.log({msg: `Card Token Holders: ${accountsToMigrate.erc721.length}`});
            for (let i = 0; i < accountsToMigrate.erc721.length; i++) {
                account = accountsToMigrate.erc721[i].owner;
                batchPass = accountsToMigrate.erc721[i].pass;
                tokenIndex = batchPass * MAX_MIGRATE_CARDS;

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

                toBeMigrated = Math.min(MAX_MIGRATE_CARDS, tokenCount - tokenIndex);
                Lib.log({msg: `Found ${tokenCount} Cards to be migrated.  Migrating ${toBeMigrated} Cards starting at ${tokenIndex}...`});

                batchTokenIds = [];
                for (; tokenIndex < tokenCount && batchTokenIds.length < MAX_MIGRATE_CARDS; tokenIndex++) {
                    // Get Old Card Token ID
                    response = await cryptoCardsTokenMigrator.cardsTokenOfOwnerByIndex(account, tokenIndex);
                    oldTokenId = web3.utils.toBN(response).toString();

                    // Get Card-Hash for Card
                    oldHash = await cryptoCardsTokenMigrator.cardHashById(oldTokenId);

                    // Convert Old Card into New Card
                    newTokenId = await _convertOldCardToNewCard(oldHash);

                    Lib.verbose && Lib.log({msg: `Adding New Card "${newTokenId}" from Old Card "${oldTokenId} (${oldHash})"...`, indent: 1});
                    batchTokenIds.push(newTokenId);
                }
                Lib.verbose && Lib.log({msg: `Migrating ${batchTokenIds.length} of ${tokenCount} Old Card-Tokens...`, indent: 1});

                // Mint New Cards
                receipt = await cryptoCardsTokenMigrator.mintNewCards(account, batchTokenIds, _getTxOptions());
                Lib.verbose && Lib.log({msg: `Successfully migrated ${batchTokenIds.length} Old Card-Tokens!`, indent: 1});
                Lib.logTxResult(receipt);
                totalGas += receipt.receipt.gasUsed;
            }
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
        Lib.log({msg: 'ERC721 Token Migration Complete!'});
        process.exit(0);
    }
    catch (err) {
        console.log(err);
        process.exit(1);
    }
};


function _packCardBits({year, gen, rank, issue, gum, eth}) {
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

    let cardHex = cardInt.toString(16);
    if (cardHex.length % 2 !== 0) { // length must be even
        cardHex = `0${cardHex}`;
    }
    return cardHex;
}

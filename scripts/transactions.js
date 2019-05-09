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

const Random = require('meteor-random');
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

const _zeroAddress = '0x0000000000000000000000000000000000000000';
const _testAccounts = [
    {address: '0x7002FF8d83625DC59A2C23bCAb9e8939A201B0d6', packs: 3, bounty: 2}, // Ganache Account 6
    {address: '0x4DE7C0BEEdD7286074fE2b9CeA08774ba55C991b', packs: 3, bounty: 3}, // Ganache Account 7
    {address: '0x2C46170cE4436Ca1e19550228777F283c0923AdB', packs: 3, bounty: 5}, // Ganache Account 8
];
const _txDelay = 1000;

Lib.network = process.env.CCC_NETWORK_NAME;
Lib.networkProvider = process.env.CCC_NETWORK_PROVIDER;
Lib.networkId = process.env.CCC_NETWORK_ID;
Lib.verbose = (process.env.CCC_VERBOSE_LOGS === 'yes');


module.exports = async function() {
    Lib.log({separator: true});
    let currentAccount = '';
    let currentAccountNonce = 0;
    let totalGas = 0;
    let receipt;
    if (_.isUndefined(networkOptions[Lib.network])) {
        Lib.network = 'local';
    }

    const options = networkOptions['local'];
    if (Lib.network !== 'local') {
        Lib.log({msg: `Network: "${Lib.network}". Skipping Load-Test Transactions.`});
        return;
    }
    const owner = process.env[`${_.toUpper(Lib.network)}_OWNER_ACCOUNT`];

    if (Lib.verbose) {
        Lib.log({separator: true});
        Lib.log({msg: `Network:   ${Lib.network}`});
        Lib.log({msg: `Web3:      ${web3.version}`});
        Lib.log({msg: `Gas Price: ${Lib.fromWeiToGwei(options.gasPrice)} GWEI`});
        Lib.log({msg: `Owner:     ${owner}`});
        Lib.log({separator: true});
    }

    Lib.deployData = require(`../zos.${Lib.networkProvider}.json`);

    const _testTransactions = [];
    for (let i = 0; i < _testAccounts.length; i++) {
        _testTransactions.push({
            method : 'buyPackOfCards',
            count  : _testAccounts[i].packs,
            params : [!i ? _zeroAddress : _testAccounts[0].address, '', '__rnd__'], // referrer, promoCode, uuid
            tx : {
                from  : _testAccounts[i].address,
                value : Lib.fromFinneyToWei(30) // 30 finney, generation 1 pack price
            }
        });
    }

    const _getRandom = (max = 16) => {
        // return web3.utils.randomHex(max);
        return Random.id(max);
    };

    const _getTxOptions = (txData) => {
        return _.assignIn({}, {
            nonce: currentAccountNonce++,
            gasPrice: options.gasPrice
        }, txData);
    };

    Lib.log({msg: 'Running Test Transactions...'});
    Lib.log({spacer: true});
    Lib.log({spacer: true});

    try {
        let testTx;
        let testParams;

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Contract Deployments
        const ddCryptoCardsController = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsController');
        const cryptoCardsController = Lib.getContractInstance(CryptoCardsController, ddCryptoCardsController.address);

        const ddCryptoCardsOracle = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsOracle');
        const cryptoCardsOracle = Lib.getContractInstance(CryptoCardsOracle, ddCryptoCardsOracle.address);

        const ddCryptoCardsTreasury = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsTreasury');
        const cryptoCardsTreasury = Lib.getContractInstance(CryptoCardsTreasury, ddCryptoCardsTreasury.address);

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Update Oracle Gas Limit for Testing
        // const oracleGasLimit = 400000; // actual cost is between 345998 - 375998
        // Lib.log({spacer: true});
        // Lib.log({msg: `Updating Oracle Gas Limit to ${oracleGasLimit}`});
        // const ownerNonce = (await Lib.getTxCount(owner)) || 0;
        // receipt = await cryptoCardsOracle.updateOracleGasLimit(oracleGasLimit, _getTxOptions({from: owner, nonce: ownerNonce}));
        // Lib.logTxResult(receipt);
        // totalGas += receipt.receipt.gasUsed;
        // await Lib.delay(_txDelay * 3);


        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Initial Bounties
        currentAccountNonce = (await Lib.getTxCount(owner)) || 0;
        let bounty;
        for (let i = 0; i < _testAccounts.length; i++) {
            currentAccount = _testAccounts[i].address;
            bounty = _testAccounts[i].bounty * 1e18;

            Lib.log({spacer: true});
            Lib.log({msg: `Adding Bounty Reward of ${bounty} ETH..`});
            receipt = await cryptoCardsTreasury.addOutsourcedMember(currentAccount, bounty, _getTxOptions({from: owner}));
            Lib.logTxResult(receipt);
            totalGas += receipt.receipt.gasUsed;
            await Lib.delay(_txDelay);
        }


        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Initial Pack Purchases
        for (let i = 0; i < _testTransactions.length; i++) {
            testTx = _.assignIn({}, _testTransactions[i]);

            if (currentAccount !== testTx.tx.from) {
                currentAccount = testTx.tx.from;
                currentAccountNonce = (await Lib.getTxCount(currentAccount)) || 0;
                Lib.log({msg: `Account "${currentAccount}" at Nonce: ${currentAccountNonce}`});
                Lib.log({spacer: true});
            }

            for (let j = 0; j < testTx.count; j++) {
                testParams = _.map(testTx.params, p => (p === '__rnd__' ? _getRandom() : p));
                Lib.log({indent: 1, msg: `${(j+1)}/${testTx.count}: Running "${testTx.method}" with params: ${JSON.stringify(testParams)}`});
                receipt = await cryptoCardsController[testTx.method](...testParams, _getTxOptions(testTx.tx));
                Lib.logTxResult(receipt);
                totalGas += receipt.receipt.gasUsed;
                await Lib.delay(_txDelay);
            }
        }

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Deploy Complete
        Lib.log({separator: true});
        Lib.log({separator: true});

        Lib.log({spacer: true});
        Lib.log({spacer: true});

        Lib.log({msg: `Total Gas Used: ${totalGas} WEI`});
        Lib.log({msg: `Gas Price:      ${Lib.fromWeiToGwei(options.gasPrice)} GWEI`});
        Lib.log({msg: `Actual Cost:    ${Lib.fromWeiToEther(totalGas * options.gasPrice)} ETH`});

        Lib.log({spacer: true});
        Lib.log({msg: 'Load-Test Transactions Complete!'});
        process.exit(0);
    }
    catch (err) {
        console.log(err);
        process.exit(1);
    }
};

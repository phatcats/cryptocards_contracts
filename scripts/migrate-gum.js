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

const CryptoCardsGumDistributor = contracts.getFromLocal('CryptoCardsGumDistributor');

Lib.network = process.env.CCC_NETWORK_NAME;
Lib.networkProvider = process.env.CCC_NETWORK_PROVIDER;
Lib.networkId = process.env.CCC_NETWORK_ID;
Lib.verbose = (process.env.CCC_VERBOSE_LOGS === 'yes');

const _migrationAccounts = {
    local: [

    ],
    ropsten: [

    ],
    mainnet: [
        '0x55b4dc1873b2b2d54e75fabcde78160a37498a06',
        '0x50c5e398267465dcbc19c512ed7ca8e345e35d67',
        '0xd02ae906edc339872b8300020fc4411c4f4036e1',
        '0x5864745720a6c4b577f07ac3fe5d39ea20f050b1',
        '0x611b009b4100e311e16c3d56557024691ea461c9',
        '0x49c094b9738af66e75e3170a81bf46ffc2bf0bdd',
        '0xba0e95a462905d45e819cdcba3a43b30f778e8cf',
        '0x5c0bcf0c97643bd9f0066734d261bdc58b564e42',
        '0x7c0d842f6857d9feacc7b1500488b9d0d3c3d8ad',
        '0x164168afa4c1c40216ae4cfee9702b8dc947683b',
        '0x398a20f8a91a7406343e75f4ac1eaad6902d3862',
        '0xb0c4adeb9b23a6512bea47d1a479bc33afbfe283'
    ]
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
    const accountsToMigrate = _migrationAccounts[Lib.network];

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
        const ddCryptoCardsGumDistributor = Lib.getDeployDataFor('cryptocardscontracts/CryptoCardsGumDistributor');
        const cryptoCardsGumDistributor = await Lib.getContractInstance(CryptoCardsGumDistributor, ddCryptoCardsGumDistributor.address);


        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Contract Token Migration
        let account;
        for (let i = 0; i < accountsToMigrate.length; i++) {
            account = accountsToMigrate[i];

            Lib.log({separator: true});
            Lib.log({spacer: true});
            Lib.log({msg: `Migrating GUM Token Holder ${account}...`});
            receipt = await cryptoCardsGumDistributor.migrateTokenHolder(account, _getTxOptions());
            console.log('receipt', JSON.stringify(receipt));
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
        Lib.log({msg: 'Token Migration Complete!'});
        process.exit(0);
    }
    catch (err) {
        console.log(err);
        process.exit(1);
    }
};

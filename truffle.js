/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2019 (c) Phat Cats, Inc.
 */

require('dotenv').config();

const HDWalletProvider = require("truffle-hdwallet-provider");
const { wallets, networkOptions } = require('./config');
const walletMnemonicType = process.env.CCC_WALLET_MNEMONIC_TYPE || 'proxy';

module.exports = {
    // See <http://truffleframework.com/docs/advanced/configuration>
    // to customize your Truffle configuration!
    networks: {
        local: {
            host          : '127.0.0.1',
            port          : 7545,
            network_id    : '5777',                             // Ganache
            gas           : networkOptions.local.gas,
            gasPrice      : networkOptions.local.gasPrice,
            confirmations : 0,                                  // # of confs to wait between deployments. (default: 0)
            timeoutBlocks : 50,                                 // # of blocks before a deployment times out  (minimum/default: 50)
            skipDryRun    : true                                // Skip dry run before migrations? (default: false for public nets)
        },
        ropsten: {
            // Return instance rather than a function, as per: https://github.com/trufflesuite/truffle-hdwallet-provider/issues/65#issuecomment-417417192
            provider      : new HDWalletProvider(wallets.ropsten.mnemonic[walletMnemonicType], wallets.ropsten.apiEndpoint, wallets.ropsten.accountIndex), //, 1, true, "m/44'/1'/0'/0/"),
            network_id    : 3,                                  // Ropsten
            gas           : networkOptions.ropsten.gas,         // https://ropsten.etherscan.io/blocks
            gasPrice      : networkOptions.ropsten.gasPrice,    // https://ropsten.etherscan.io/gastracker
            confirmations : 0,                                  // # of confs to wait between deployments. (default: 0)
            timeoutBlocks : 200,                                // # of blocks before a deployment times out  (minimum/default: 50)
            skipDryRun    : false                               // Skip dry run before migrations? (default: false for public nets)
        },
        mainnet: {
            provider      : new HDWalletProvider(wallets.mainnet.mnemonic[walletMnemonicType], wallets.mainnet.apiEndpoint, wallets.mainnet.accountIndex),
            network_id    : 1,                                  // Mainnet
            gas           : networkOptions.mainnet.gas,         // https://etherscan.io/blocks
            gasPrice      : networkOptions.mainnet.gasPrice,    // https://etherscan.io/gastracker
            confirmations : 1,                                  // # of confs to wait between deployments. (default: 0)
            timeoutBlocks : 200,                                // # of blocks before a deployment times out  (minimum/default: 50)
            skipDryRun    : false                               // Skip dry run before migrations? (default: false for public nets)
        }
    },
    compilers: {
        solc: {
            version: '0.5.0',
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
    mocha: {
        reporter: 'eth-gas-reporter',
        reporterOptions : {
            currency: 'USD',
            gasPrice: 21,
            showTimeSpent: true
        }
    }
};

/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2019 (c) Phat Cats, Inc.
 */

// const { Contracts } = require('zos-lib');

module.exports = {
    wallets: {
        ropsten: {
            apiEndpoint: `https://ropsten.infura.io/v3/${process.env.ROPSTEN_INFURA_API_KEY}`,
            mnemonic: {
                proxy: process.env.ROPSTEN_WALLET_MNEMONIC_PROXY,
                owner: process.env.ROPSTEN_WALLET_MNEMONIC_OWNER
            },
            accountIndex: 0
        },
        mainnet: {
            apiEndpoint: `https://mainnet.infura.io/v3/${process.env.MAINNET_INFURA_API_KEY}`,
            mnemonic: {
                proxy: process.env.MAINNET_WALLET_MNEMONIC_PROXY,
                owner: process.env.MAINNET_WALLET_MNEMONIC_OWNER
            },
            accountIndex: 0
        }
    },

    networkOptions: {
        local: {
            oracleApiEndpoint   : 'BEJLg+4QyJdFu5IeCfdZrVnurkh/GB9aEY6rGDuyHSBLtOs1BsPdo0/aTr6qaIVvLlPZUku8TT7PEFY6OwbQqa6l/+ATw2Uf+iWkhjsg5seU31FHvahFHELYm1Kuu5B46g0h1biap3OtXDzys4RZgQ6HDNbF3eq9Xw4Zwi2vzQlt/LSp3lJHpmuYWu78y/Ed5Ov4OiAaoVhPIkRFN+8rDpcQIXEXdzlHTZBAACWJ6gE=',
            gumPerPack          : 60,
            gas                 : 6721975,
            minGasPrice         : 10 * 1e9,
            gasPrice            : 90 * 1e9
        },
        ropsten: {
            oracleApiEndpoint   : 'BI33RiqK+ljYzlRuu0pdF23DTia8iiC+TCCbqCmQzZdpIH/WrKr8x1w92VNZgTzptK9HwbMQCBXH69bA0bVuo1O4PIRCDbXJdYp78VDKp1s4lFE8+W4q2X2w3nzB+dgcjEGC2GVyvqihLOwH0o7E1HEtlgeLdapzLcWeNwmIVtGHGpfk30i/qD14vwXnPT7lO9ndbwEHlb4w5Q2YkUDKrWyF3g10IgrBk1Wp8fYyTg4bji4=',
            gumPerPack          : 60,
            // For contract deployments
            // gas                : 8000000,  // https://ropsten.etherscan.io/blocks
            // For contract interactions
            gas                 : 1000000,
            minGasPrice         : 20 * 1e9,
            gasPrice            : 50 * 1e9   // Max Gas Price to Pay; https://ropsten.etherscan.io/gastracker
        },
        mainnet: {
            oracleApiEndpoint   : 'BP00gRkhrJdkE9+lyEJmZZcmK1Pq1R6WpyZM1ZislsSxFhGo+YzxSOFT4/a9jfEbFlwKMog53Z6wMzem14mKXfvSQOklp1WpCit2KZ6nmTvGBx/96cpTXvtuH90eZglas5F9qPcv75tqSexG2Yb6zWVIwVV0C0sFXsElfg75Sf9tjyPgqaQuQOGxKhza1SUESziEYDy2onUbM12LBlL7H75nnyAoVpcdiMfGgMEGSrGZnsgM29uIxJmG',
            gumPerPack          : 60,
            // For contract deployments
            // gas                : 8000000,  // https://etherscan.io/blocks
            // For contract interactions
            gas                 : 1000000,  // https://etherscan.io/blocks
            minGasPrice         : 1 * 1e9,
            gasPrice            : 2 * 1e9   // Max Gas Price to Pay; https://etherscan.io/gastracker
        }
    },

    tokenAddresses: {
        local: {
            oldPacksCtrl  : '0x856ee8736b204f926c33db5929328ba950768b6a',
            oldCardsCtrl  : '0xaad8b7860cf6bb209f9e60f68aae438b2d076ca6',
            oldCardsToken : '0x81D7E3648579E27679bFc3010e673532BF77c379',
            oldGumToken   : '0x529e6171559eFb0c49644d7b281BC5997c286CBF'
        },
        ropsten: {
            oldPacksCtrl  : '0x856ee8736b204f926c33db5929328ba950768b6a',
            oldCardsCtrl  : '0xaad8b7860cf6bb209f9e60f68aae438b2d076ca6',
            oldCardsToken : '0x81D7E3648579E27679bFc3010e673532BF77c379',
            oldGumToken   : '0x529e6171559eFb0c49644d7b281BC5997c286CBF'
        },
        mainnet: {
            oldPacksCtrl  : '0x56b3c4957cc15e2ad81563b0560a680a433db43e',
            oldCardsCtrl  : '0x4b9134c7484907fe683d6521ad743c18fe1375c2',
            oldCardsToken : '0xcb35d14759e2931022c7315f53e37cdcd38e570c',
            oldGumToken   : '0xaAFa4Bf1696732752a4AD4D27DD1Ea6793F24Fc0'
        }
    },

    migrationPhase: {
        migratePacks : true,
        migrateCards : true,
        batchSize    : 3,
    },

    migrationAccounts: {
        local: {
            erc20: [
            ],
            erc721: [
            ]
        },
        ropsten: {
            erc20: [
                '0x107EB6166d59350C634B1DcFDffBaD4846CCCD84', // Account 9
                '0x8b7ab7c6bb27c7ae707f751e444eed4998aaea7b', // Account 10
            ],
            erc721: [
                '0xaf06e78152d5ba4df6b116fdbca87bc13181e994',
                '0x107eb6166d59350c634b1dcfdffbad4846cccd84', // Account 9
                '0x8b7ab7c6bb27c7ae707f751e444eed4998aaea7b', // Account 10
                '0xcd3a3d04560b54f9af22a87005aec435d42ddb92',
            ]
        },
        mainnet: {
            erc20: [
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
        }
    },

    contracts: {
        getFromLocal: function(contractName) {
            // return Contracts.getFromLocal(contractName);
            return artifacts.require(`${contractName}.sol`);
        }
    }

};

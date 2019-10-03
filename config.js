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
            gumPerPack          : '60000000000000000000',
            gas                 : 6721975,
            minGasPrice         : 10e9,
            gasPrice            : 90e9
        },
        ropsten: {
            oracleApiEndpoint   : 'BI33RiqK+ljYzlRuu0pdF23DTia8iiC+TCCbqCmQzZdpIH/WrKr8x1w92VNZgTzptK9HwbMQCBXH69bA0bVuo1O4PIRCDbXJdYp78VDKp1s4lFE8+W4q2X2w3nzB+dgcjEGC2GVyvqihLOwH0o7E1HEtlgeLdapzLcWeNwmIVtGHGpfk30i/qD14vwXnPT7lO9ndbwEHlb4w5Q2YkUDKrWyF3g10IgrBk1Wp8fYyTg4bji4=',
            gumPerPack          : '60000000000000000000',
            // For contract deployments
            gas                 : 4500000,  // https://ropsten.etherscan.io/blocks
            // For contract interactions
            // gas                 : 300000,
            minGasPrice         : 22e9,
            gasPrice            : 50e9      // Max Gas Price to Pay; https://ropsten.etherscan.io/gastracker
        },
        mainnet: {
            oracleApiEndpoint   : 'BLOCEBTvc+CkbkM3HFDelDmZn8z+GBw+K2TRHqf2FF1G2VZHxkAUc/ShHisEI9KyJGkfyqa2kUs2fiXCrwF8l2TYDjHcByZ0szQttEz3W/5Yd5Tv4fdOdkm9h2XXPJu+bRBByLj+HqXDttXOTOzSbH/d2RezvRSyoLrA3hSmN1NjWsA93aGcSg4NCfrHUDU0jP3/xrfnlDF499xc+0/d7ZUy+tVN53zYqVF2ws32z+4JkwoynFYlr4F8',
            gumPerPack          : '60000000000000000000',
            // For contract deployments
            // gas                 : 4500000,  // https://etherscan.io/blocks
            // For contract interactions
            gas                 : 5000000,  // https://etherscan.io/blocks
            minGasPrice         : 6e9,
            gasPrice            : 6e9       // Max Gas Price to Pay; https://etherscan.io/gastracker
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
            oldPacksCtrl  : '0x9fe807eadeb031b133c099165c00cff519c32ac6',
            oldCardsCtrl  : '0xe10f8f13addda57869cdf800aab4c0d5de9fa585',
            oldCardsToken : '0xcb35d14759e2931022c7315f53e37cdcd38e570c',
            oldGumToken   : '0xaAFa4Bf1696732752a4AD4D27DD1Ea6793F24Fc0'
        }
    },

    migrationPhase: {
        migratePacks : false,
        migrateCards : true,
        migratePurchasedPacks: false,
        batchSize    : 40,
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
                '0xaf06e78152d5ba4df6b116fdbca87bc13181e994', // Account 6
                '0x107eb6166d59350c634b1dcfdffbad4846cccd84', // Account 9
                '0x8b7ab7c6bb27c7ae707f751e444eed4998aaea7b', // Account 10
                '0xcd3a3d04560b54f9af22a87005aec435d42ddb92', // Account 5
            ],
            packPurchasers: [
                {account: '0xaf06e78152d5ba4df6b116fdbca87bc13181e994', count: '100'},
            ]
        },
        mainnet: {
            erc20: [
                // '0x55b4dc1873b2b2d54e75fabcde78160a37498a06',
                // '0x50c5e398267465dcbc19c512ed7ca8e345e35d67',
                // '0xd02ae906edc339872b8300020fc4411c4f4036e1',
                // '0x5864745720a6c4b577f07ac3fe5d39ea20f050b1',
                // '0x611b009b4100e311e16c3d56557024691ea461c9',
                // '0x49c094b9738af66e75e3170a81bf46ffc2bf0bdd',
                // '0xba0e95a462905d45e819cdcba3a43b30f778e8cf',
                // '0x5c0bcf0c97643bd9f0066734d261bdc58b564e42',
                // '0x7c0d842f6857d9feacc7b1500488b9d0d3c3d8ad',
                // '0x164168afa4c1c40216ae4cfee9702b8dc947683b',
                // '0x398a20f8a91a7406343e75f4ac1eaad6902d3862',
                // '0xb0c4adeb9b23a6512bea47d1a479bc33afbfe283',
                // '0x6f5256bd895cdac8c8c2bc5a90da1d8b93f3dfd5',
                // '0xe9c80eebb0376e8775abd56823154fadb5710505',
            ],
            erc721: [
                // '0x5864745720a6c4b577f07ac3fe5d39ea20f050b1', // no cards
                // '0xb6d820e80a2a7c49f94c9d6c8ea08dccedc9ce4c', // no cards
                // '0xfe5a65645f2dc8fa5fbcdb7a578ee65dbaa3476d', // no cards
                // '0x6f5256bd895cdac8c8c2bc5a90da1d8b93f3dfd5', // no cards
                // '0xf8cfe7dff8528dfc98cec446335ec6e40b902ebc', // no cards
                // '0x49c094b9738af66e75e3170a81bf46ffc2bf0bdd', //   1 /   1
                // '0x611b009b4100e311e16c3d56557024691ea461c9', //   3 /   3
                // '0x025e0bfa4624ad504b39223a5674424b39145f2a', //   4 /   4
                // '0x25f10d30fcaaf00d6e3e8560bfcff720dbe554bd', //   5 /   5
                // '0xb0c4adeb9b23a6512bea47d1a479bc33afbfe283', //   8 /   8
                // '0xbe292285df36aefc0a464800755498abf19e4052', //   8 /   8
                // '0x50c5e398267465dcbc19c512ed7ca8e345e35d67', //   9 /   9
                // '0xd02ae906edc339872b8300020fc4411c4f4036e1', //  16 /  16
                // '0x7c0d842f6857d9feacc7b1500488b9d0d3c3d8ad', //  24 /  24
                // '0x5c0bcf0c97643bd9f0066734d261bdc58b564e42', //  24 /  24
                // '0xe9c80eebb0376e8775abd56823154fadb5710505', //  27 /  27
                // '0x164168afa4c1c40216ae4cfee9702b8dc947683b', //  39 /  39
                // '0x398a20f8a91a7406343e75f4ac1eaad6902d3862', //  40 /  40
                // '0x55b4dc1873b2b2d54e75fabcde78160a37498a06', // 176 / 176
                // '0xba0e95a462905d45e819cdcba3a43b30f778e8cf', // 184 / 184
                // '0x690e88867b1eab78ac51366fa2ff61880182a7e9', // 472 / 472
            ],
            packPurchasers: [
                // {account: '0x5864745720a6c4b577f07ac3fe5d39ea20f050b1', count: '1'},
                // {account: '0xb6d820e80a2a7c49f94c9d6c8ea08dccedc9ce4c', count: '2'},
                // {account: '0xfe5a65645f2dc8fa5fbcdb7a578ee65dbaa3476d', count: '1'},
                // {account: '0x6f5256bd895cdac8c8c2bc5a90da1d8b93f3dfd5', count: '4'},
                // {account: '0xf8cfe7dff8528dfc98cec446335ec6e40b902ebc', count: '6'},
                // {account: '0x49c094b9738af66e75e3170a81bf46ffc2bf0bdd', count: '14'},
                // {account: '0x611b009b4100e311e16c3d56557024691ea461c9', count: '16'},
                // {account: '0x025e0bfa4624ad504b39223a5674424b39145f2a', count: '2'},
                // {account: '0x25f10d30fcaaf00d6e3e8560bfcff720dbe554bd', count: '0'},
                // {account: '0xb0c4adeb9b23a6512bea47d1a479bc33afbfe283', count: '1'},
                // {account: '0xbe292285df36aefc0a464800755498abf19e4052', count: '1'},
                // {account: '0x50c5e398267465dcbc19c512ed7ca8e345e35d67', count: '2'},
                // {account: '0xd02ae906edc339872b8300020fc4411c4f4036e1', count: '4'},
                // {account: '0x7c0d842f6857d9feacc7b1500488b9d0d3c3d8ad', count: '7'},
                // {account: '0x5c0bcf0c97643bd9f0066734d261bdc58b564e42', count: '10'},
                // {account: '0xe9c80eebb0376e8775abd56823154fadb5710505', count: '4'},
                // {account: '0x164168afa4c1c40216ae4cfee9702b8dc947683b', count: '19'},
                // {account: '0x398a20f8a91a7406343e75f4ac1eaad6902d3862', count: '5'},
                // {account: '0x55b4dc1873b2b2d54e75fabcde78160a37498a06', count: '104'},
                // {account: '0xba0e95a462905d45e819cdcba3a43b30f778e8cf', count: '43'},
                // {account: '0x690e88867b1eab78ac51366fa2ff61880182a7e9', count: '60'},
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

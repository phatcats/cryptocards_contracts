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
            // oracleApiEndpoint: 'BAUD89qAzoJsLlajETu6INZFbd5GnNfeg6ZTJbe0hq2ltEOctlwLrsDuMTMffqEUMbGoioZEzjDqhu314KVzZFw9/IVnbar5mVxS/mhmSN+NfrDRXW5Sxpsdds+epmMiSJ+URKsSCAAGljpjoesWcukFmU2UPy1apKKU5OpKpGc3AzowXOViIaG4BXG++rWZ1NMv/xVjHQKqSYTHx4qlQAJH94RcZtoQuz4+x0PwJv/RUQ==',
            // oracleApiEndpoint: 'BL5iQLuZFIoMp3mXKb/Nt4C0cq/MDtCB6cZjYxve4bsvWzcvyWjp61XaENaMlc02cvbeK2jAohabMRXhj8q8jw1pFeSx8DQxkmMU0enzCqoxA/VcX2vvxJSuq71RmBTLfqT/+gu4tlHn1y7US2lGMYTCBI23775TkCKpS4c0Qe/KoHfxYAWFsWfcbKr0hcjMihobOJA7k0/8Jb3uaxA9Qf+92I/zQPwKVxY/RSXxdIU=',
            oracleApiEndpoint   : 'BEJLg+4QyJdFu5IeCfdZrVnurkh/GB9aEY6rGDuyHSBLtOs1BsPdo0/aTr6qaIVvLlPZUku8TT7PEFY6OwbQqa6l/+ATw2Uf+iWkhjsg5seU31FHvahFHELYm1Kuu5B46g0h1biap3OtXDzys4RZgQ6HDNbF3eq9Xw4Zwi2vzQlt/LSp3lJHpmuYWu78y/Ed5Ov4OiAaoVhPIkRFN+8rDpcQIXEXdzlHTZBAACWJ6gE=',
            gumPerPack          : 60,
            gas                 : 6721975,
            gasPrice            : 20000000000          // (20 Gwei)
        },
        ropsten: {
            // oracleApiEndpoint: 'BL5iQLuZFIoMp3mXKb/Nt4C0cq/MDtCB6cZjYxve4bsvWzcvyWjp61XaENaMlc02cvbeK2jAohabMRXhj8q8jw1pFeSx8DQxkmMU0enzCqoxA/VcX2vvxJSuq71RmBTLfqT/+gu4tlHn1y7US2lGMYTCBI23775TkCKpS4c0Qe/KoHfxYAWFsWfcbKr0hcjMihobOJA7k0/8Jb3uaxA9Qf+92I/zQPwKVxY/RSXxdIU=',
            oracleApiEndpoint   : 'BEJLg+4QyJdFu5IeCfdZrVnurkh/GB9aEY6rGDuyHSBLtOs1BsPdo0/aTr6qaIVvLlPZUku8TT7PEFY6OwbQqa6l/+ATw2Uf+iWkhjsg5seU31FHvahFHELYm1Kuu5B46g0h1biap3OtXDzys4RZgQ6HDNbF3eq9Xw4Zwi2vzQlt/LSp3lJHpmuYWu78y/Ed5Ov4OiAaoVhPIkRFN+8rDpcQIXEXdzlHTZBAACWJ6gE=',
            gumPerPack          : 60,
            gas                 : 8000000,
            gasPrice            : 30000000000          // https://ropsten.etherscan.io/gastracker  (30 Gwei)
        },
        mainnet: {
            oracleApiEndpoint   : 'BP00gRkhrJdkE9+lyEJmZZcmK1Pq1R6WpyZM1ZislsSxFhGo+YzxSOFT4/a9jfEbFlwKMog53Z6wMzem14mKXfvSQOklp1WpCit2KZ6nmTvGBx/96cpTXvtuH90eZglas5F9qPcv75tqSexG2Yb6zWVIwVV0C0sFXsElfg75Sf9tjyPgqaQuQOGxKhza1SUESziEYDy2onUbM12LBlL7H75nnyAoVpcdiMfGgMEGSrGZnsgM29uIxJmG',
            // For contract deployments
            // gas                : 8000000,           // https://etherscan.io/blocks
            // For contract interactions
            gumPerPack          : 60,
            gas                 : 1000000,             // https://etherscan.io/blocks
            gasPrice            : 2000000000           // https://etherscan.io/gastracker  (1 Gwei)
        }
    },

    tokenAddresses: {
        local: {
            packsToken    : '0x01b9707dD7782bB441ec57C1B62D669896859096',
            cardsToken    : '0x89eC3f11E1600BEd981DD2d12404bAAF21c7699c',
            gumToken      : '0xF70B61E3800dFFDA57cf167051CAa0Fb6bA1B0B3',
            oldPacksCtrl  : '',
            oldCardsCtrl  : '',
            oldCardsToken : '',
            oldGumToken   : ''
        },
        ropsten: {
            packsToken    : '0xc0e043EB91aea2e4543b3a019bd5C8aa494813D6',
            cardsToken    : '0x1f5B351E9E383d133bea2CD2F5506Db5e3f71e2B',
            gumToken      : '0x1181C791a125c8Dd7DDF55Ee3c5471f5Da71F845',
            oldPacksCtrl  : '0x856ee8736b204f926c33db5929328ba950768b6a',
            oldCardsCtrl  : '0xaad8b7860cf6bb209f9e60f68aae438b2d076ca6',
            oldCardsToken : '0x81D7E3648579E27679bFc3010e673532BF77c379',
            oldGumToken   : '0x529e6171559eFb0c49644d7b281BC5997c286CBF'
        },
        mainnet: {
            packsToken    : '',
            cardsToken    : '',
            gumToken      : '',
            oldPacksCtrl  : '0x0683e840ea22b089dafa0bf8c59f1a9690de7c12',
            oldCardsCtrl  : '',
            oldCardsToken : '',
            oldGumToken   : '0xaafa4bf1696732752a4ad4d27dd1ea6793f24fc0'
        }
    },

    migrationAccounts: {
        local: [

        ],
        ropsten: {
            erc20: [
                '0x107EB6166d59350C634B1DcFDffBaD4846CCCD84', // Account 9
                '0x8b7ab7c6bb27c7ae707f751e444eed4998aaea7b', // Account 10 - migrated
            ],
            erc721: [
                '0x107EB6166d59350C634B1DcFDffBaD4846CCCD84',
                '0xcd3a3d04560b54f9af22a87005aec435d42ddb92'
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

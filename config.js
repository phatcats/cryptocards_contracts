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

    contracts: {
        getFromLocal: function(contractName) {
            // return Contracts.getFromLocal(contractName);
            return artifacts.require(`${contractName}.sol`);
        }
    }

};

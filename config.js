/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2018 (c) Phat Cats, Inc.
 */

module.exports = {
    wallets: {
        ropsten: {
            apiEndpoint: `https://ropsten.infura.io/v3/${process.env.ROPSTEN_INFURA_API_KEY}`,
            mnemonic: process.env.ROPSTEN_WALLET_MNEMONIC,
            accountIndex: 0
        },
        mainnet: {
            apiEndpoint: `https://ropsten.infura.io/v3/${process.env.MAINNET_INFURA_API_KEY}`,
            mnemonic: process.env.MAINNET_WALLET_MNEMONIC,
            accountIndex: 0
        }
    },

    networkOptions: {
        local: {
            // https://api-local.crypto-cards.io
            oracleApiEndpoint: 'BAUD89qAzoJsLlajETu6INZFbd5GnNfeg6ZTJbe0hq2ltEOctlwLrsDuMTMffqEUMbGoioZEzjDqhu314KVzZFw9/IVnbar5mVxS/mhmSN+NfrDRXW5Sxpsdds+epmMiSJ+URKsSCAAGljpjoesWcukFmU2UPy1apKKU5OpKpGc3AzowXOViIaG4BXG++rWZ1NMv/xVjHQKqSYTHx4qlQAJH94RcZtoQuz4+x0PwJv/RUQ==',
            packPrices: [35, 40, 45], // finney
            promoCodes: [5, 10, 15],
            gasPrice: 20000000000     // (20 Gwei)
        },
        ropsten: {
            // https://api-ropsten.crypto-cards.io
            oracleApiEndpoint: 'BL5iQLuZFIoMp3mXKb/Nt4C0cq/MDtCB6cZjYxve4bsvWzcvyWjp61XaENaMlc02cvbeK2jAohabMRXhj8q8jw1pFeSx8DQxkmMU0enzCqoxA/VcX2vvxJSuq71RmBTLfqT/+gu4tlHn1y7US2lGMYTCBI23775TkCKpS4c0Qe/KoHfxYAWFsWfcbKr0hcjMihobOJA7k0/8Jb3uaxA9Qf+92I/zQPwKVxY/RSXxdIU=',
            packPrices: [35, 40, 45], // finney
            promoCodes: [5, 10, 15],
            gasPrice: 20000000000   // https://ropsten.etherscan.io/gastracker  (20 Gwei)
        },
        mainnet: {
            // https://api.crypto-cards.io
            oracleApiEndpoint: '',
            packPrices: [35, 40, 45], // finney
            promoCodes: [],
            gasPrice: 1000000000   // https://etherscan.io/gastracker  (1 Gwei)
        }
    }
};
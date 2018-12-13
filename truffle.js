
const HDWalletProvider = require("truffle-hdwallet-provider");
const wallets = {
    ropsten: {
        apiEndpoint: "https://ropsten.infura.io/v3/13e30b59fdd54c29991c5277c1720660",
        mnemonic: "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat",
        accountIndex: 0
    },
    mainnet: {
        apiEndpoint: "https://ropsten.infura.io/v3/13e30b59fdd54c29991c5277c1720660",
        mnemonic: "",
        accountIndex: 0
    }
};

module.exports = {
    // See <http://truffleframework.com/docs/advanced/configuration>
    // to customize your Truffle configuration!
    networks: {
        local: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "5777",      // Ganache
            gas: 6721975,
            gasPrice: 20000000000,   // https://ropsten.etherscan.io/gastracker  (20 Gwei)
            confirmations: 0,        // # of confs to wait between deployments. (default: 0)
            timeoutBlocks: 50,       // # of blocks before a deployment times out  (minimum/default: 50)
            skipDryRun: true         // Skip dry run before migrations? (default: false for public nets)
        },
        ropsten: {
            provider: function() {
                return new HDWalletProvider(wallets.ropsten.mnemonic, wallets.ropsten.apiEndpoint, wallets.ropsten.accountIndex);
            },
            network_id: 3,           // Ropsten
            gas: 8000000,            // https://ropsten.etherscan.io/blocks
            gasPrice: 20000000000,   // https://ropsten.etherscan.io/gastracker  (20 Gwei)
            confirmations: 2,        // # of confs to wait between deployments. (default: 0)
            timeoutBlocks: 200,      // # of blocks before a deployment times out  (minimum/default: 50)
            skipDryRun: false        // Skip dry run before migrations? (default: false for public nets)
        },
        mainnet: {
            provider: function() {
                return new HDWalletProvider(wallets.mainnet.mnemonic, wallets.mainnet.apiEndpoint, wallets.mainnet.accountIndex);
            },
            network_id: 1,           // Mainnet
            gas: 8000000,            // https://etherscan.io/blocks
            gasPrice: 1000000000,    // https://etherscan.io/gastracker  (1 Gwei)
            confirmations: 3,        // # of confs to wait between deployments. (default: 0)
            timeoutBlocks: 200,      // # of blocks before a deployment times out  (minimum/default: 50)
            skipDryRun: false        // Skip dry run before migrations? (default: false for public nets)
        }
    },
    compilers: {
        solc: {
            version: '0.4.24',
            optimizer: {
                enabled: true
            }
        }
    },
    mocha: {
        reporter: 'eth-gas-reporter',
        reporterOptions : {
            currency: 'CAD',
            gasPrice: 21,
            showTimeSpent: true
        }
    }
};

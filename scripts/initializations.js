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

const { Contracts } = require('zos-lib');
const { Lib } = require('./common');
const { networkOptions } = require('../config');
const _ = require('lodash');

const StandaloneERC20 = Contracts.getFromLocal('StandaloneERC20');
const StandaloneERC721 = Contracts.getFromLocal('StandaloneERC721');
const CryptoCardsTreasury = Contracts.getFromLocal('CryptoCardsTreasury');
const CryptoCardsOracle = Contracts.getFromLocal('CryptoCardsOracle');
const CryptoCardsLib = Contracts.getFromLocal('CryptoCardsLib');
const CryptoCardsGum = Contracts.getFromLocal('CryptoCardsGum');
const CryptoCards = Contracts.getFromLocal('CryptoCards');
const CryptoCardPacks = Contracts.getFromLocal('CryptoCardPacks');
const CryptoCardsController = Contracts.getFromLocal('CryptoCardsController');

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
    const proxyAdmin = process.env[`${_.toUpper(Lib.network)}_PROXY_ADMIN`];
    const owner = process.env[`${_.toUpper(Lib.network)}_OWNER_ACCOUNT`];
    const inHouseAccount = process.env[`${_.toUpper(Lib.network)}_IN_HOUSE_ACCOUNT`];
    const bountyAccount = process.env[`${_.toUpper(Lib.network)}_BOUNTY_ACCOUNT`];
    const marketingAccount = process.env[`${_.toUpper(Lib.network)}_MARKETING_ACCOUNT`];
    const exchangeAccount = process.env[`${_.toUpper(Lib.network)}_EXCHANGE_ACCOUNT`];

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
        const ddCryptoCardsOracle = Lib.getDeployDataFor('cryptocards_contracts/CryptoCardsOracle');
        const cryptoCardsOracle = Lib.getContractInstance(CryptoCardsOracle, ddCryptoCardsOracle.address);

        const ddCryptoCardsTreasury = Lib.getDeployDataFor('cryptocards_contracts/CryptoCardsTreasury');
        const cryptoCardsTreasury = Lib.getContractInstance(CryptoCardsTreasury, ddCryptoCardsTreasury.address);

        const ddCryptoCardsLib = Lib.getDeployDataFor('cryptocards_contracts/CryptoCardsLib');
        const cryptoCardsLib = Lib.getContractInstance(CryptoCardsLib, ddCryptoCardsLib.address);

        const ddCryptoCardsGum = Lib.getDeployDataFor('cryptocards_contracts/CryptoCardsGum');
        const cryptoCardsGum = Lib.getContractInstance(CryptoCardsGum, ddCryptoCardsGum.address);
        const ddCryptoCardsGumToken = Lib.getDeployDataFor('openzeppelin-eth/StandaloneERC20');
        const cryptoCardsGumToken = Lib.getContractInstance(StandaloneERC20, ddCryptoCardsGumToken.address);

        const ddCryptoCards = Lib.getDeployDataFor('cryptocards_contracts/CryptoCards');
        const cryptoCards = Lib.getContractInstance(CryptoCards, ddCryptoCards.address);
        const ddCryptoCardsERC721 = Lib.getDeployDataFor('openzeppelin-eth/StandaloneERC721');
        const cryptoCardsToken = Lib.getContractInstance(StandaloneERC721, ddCryptoCardsERC721.address);

        const ddCryptoCardPacks = Lib.getDeployDataFor('cryptocards_contracts/CryptoCardPacks');
        const cryptoCardPacks = Lib.getContractInstance(CryptoCardPacks, ddCryptoCardPacks.address);
        const ddCryptoCardPacksERC721 = Lib.getDeployDataFor('openzeppelin-eth/StandaloneERC721', 1);
        const cryptoCardPacksToken = Lib.getContractInstance(StandaloneERC721, ddCryptoCardPacksERC721.address);

        const ddCryptoCardsController = Lib.getDeployDataFor('cryptocards_contracts/CryptoCardsController');
        const cryptoCardsController = Lib.getContractInstance(CryptoCardsController, ddCryptoCardsController.address);


        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Contract Linking & Initialization

        //
        // CryptoCardsOracle
        //
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Oracle to Controller...'});
        Lib.verbose && Lib.log({msg: `Controller: ${ddCryptoCardsController.address}`, indent: 1});
        receipt = await cryptoCardsOracle.setContractController(ddCryptoCardsController.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Oracle to Packs...'});
        Lib.verbose && Lib.log({msg: `Packs: ${ddCryptoCardPacks.address}`, indent: 1});
        receipt = await cryptoCardsOracle.setPacksAddress(ddCryptoCardPacks.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Oracle to Treasury...'});
        Lib.verbose && Lib.log({msg: `Treasury: ${ddCryptoCardsTreasury.address}`, indent: 1});
        receipt = await cryptoCardsOracle.setTreasuryAddress(ddCryptoCardsTreasury.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Oracle to Lib...'});
        Lib.verbose && Lib.log({msg: `Lib: ${ddCryptoCardsLib.address}`, indent: 1});
        receipt = await cryptoCardsOracle.setLibAddress(ddCryptoCardsLib.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCardsTreasury
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Treasury to Controller...'});
        Lib.verbose && Lib.log({msg: `Controller: ${ddCryptoCardsController.address}`, indent: 1});
        receipt = await cryptoCardsTreasury.setContractController(ddCryptoCardsController.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Treasury to In-House Account...'});
        Lib.verbose && Lib.log({msg: `In-House Account: ${inHouseAccount}`, indent: 1});
        receipt = await cryptoCardsTreasury.setInHouseAccount(inHouseAccount, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCardsGum
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Gum to Packs...'});
        Lib.verbose && Lib.log({msg: `Packs: ${ddCryptoCardPacks.address}`, indent: 1});
        receipt = await cryptoCardsGum.setPacksAddress(ddCryptoCardPacks.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Gum to Treasury...'});
        Lib.verbose && Lib.log({msg: `Treasury: ${ddCryptoCardsTreasury.address}`, indent: 1});
        receipt = await cryptoCardsGum.setTreasuryAddress(ddCryptoCardsTreasury.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Gum to ERC20 Token...'});
        Lib.verbose && Lib.log({msg: `ERC20 Token: ${ddCryptoCardsGumToken.address}`, indent: 1});
        receipt = await cryptoCardsGum.setGumToken(ddCryptoCardsGumToken.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCards
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Cards to Controller...'});
        Lib.verbose && Lib.log({msg: `Controller: ${ddCryptoCardsController.address}`, indent: 1});
        receipt = await cryptoCards.setContractController(ddCryptoCardsController.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Cards to Packs...'});
        Lib.verbose && Lib.log({msg: `Packs: ${ddCryptoCardPacks.address}`, indent: 1});
        receipt = await cryptoCards.setPacksAddress(ddCryptoCardPacks.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Cards to ERC721 Token...'});
        Lib.verbose && Lib.log({msg: `ERC721 Token: ${ddCryptoCardsERC721.address}`, indent: 1});
        receipt = await cryptoCards.setErcToken(ddCryptoCardsERC721.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Cards to Lib...'});
        Lib.verbose && Lib.log({msg: `Lib: ${ddCryptoCardsLib.address}`, indent: 1});
        receipt = await cryptoCards.setLibAddress(ddCryptoCardsLib.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Updating Card Minter with address to Cards...'});
        Lib.verbose && Lib.log({msg: `Cards: ${ddCryptoCards.address}`, indent: 1});
        receipt = await cryptoCardsToken.addMinter(ddCryptoCards.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCardPacks
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Packs to Controller...'});
        Lib.verbose && Lib.log({msg: `Controller: ${ddCryptoCardsController.address}`, indent: 1});
        receipt = await cryptoCardPacks.setContractController(ddCryptoCardsController.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Packs to Oracle...'});
        Lib.verbose && Lib.log({msg: `Oracle: ${ddCryptoCardsOracle.address}`, indent: 1});
        receipt = await cryptoCardPacks.setOracleAddress(ddCryptoCardsOracle.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Packs to ERC721 Token...'});
        Lib.verbose && Lib.log({msg: `ERC721 Token: ${ddCryptoCardPacksERC721.address}`, indent: 1});
        receipt = await cryptoCardPacks.setErcToken(ddCryptoCardPacksERC721.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Packs to Cards...'});
        Lib.verbose && Lib.log({msg: `Cards: ${ddCryptoCards.address}`, indent: 1});
        receipt = await cryptoCardPacks.setCardsAddress(ddCryptoCards.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Packs to Gum...'});
        Lib.verbose && Lib.log({msg: `Gum: ${ddCryptoCardsGum.address}`, indent: 1});
        receipt = await cryptoCardPacks.setGumAddress(ddCryptoCardsGum.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Packs to Lib...'});
        Lib.verbose && Lib.log({msg: `Lib: ${ddCryptoCardsLib.address}`, indent: 1});
        receipt = await cryptoCardPacks.setLibAddress(ddCryptoCardsLib.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Updating Pack Minter with address to Packs...'});
        Lib.verbose && Lib.log({msg: `Packs: ${ddCryptoCardPacks.address}`, indent: 1});
        receipt = await cryptoCardPacksToken.addMinter(ddCryptoCardPacks.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // CryptoCardsController
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Controller to Oracle...'});
        Lib.verbose && Lib.log({msg: `Oracle: ${ddCryptoCardsOracle.address}`, indent: 1});
        receipt = await cryptoCardsController.setOracleAddress(ddCryptoCardsOracle.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Controller to Cards...'});
        Lib.verbose && Lib.log({msg: `Cards: ${ddCryptoCards.address}`, indent: 1});
        receipt = await cryptoCardsController.setCardsAddress(ddCryptoCards.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Controller to Packs...'});
        Lib.verbose && Lib.log({msg: `Packs: ${ddCryptoCardPacks.address}`, indent: 1});
        receipt = await cryptoCardsController.setPacksAddress(ddCryptoCardPacks.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Controller to Treasury...'});
        Lib.verbose && Lib.log({msg: `Treasury: ${ddCryptoCardsTreasury.address}`, indent: 1});
        receipt = await cryptoCardsController.setTreasuryAddress(ddCryptoCardsTreasury.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Controller to Gum...'});
        Lib.verbose && Lib.log({msg: `Gum: ${ddCryptoCardsGum.address}`, indent: 1});
        receipt = await cryptoCardsController.setGumAddress(ddCryptoCardsGum.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        Lib.log({spacer: true});
        Lib.log({msg: 'Linking Controller to Lib...'});
        Lib.verbose && Lib.log({msg: `Lib: ${ddCryptoCardsLib.address}`, indent: 1});
        receipt = await cryptoCardsController.setLibAddress(ddCryptoCardsLib.address, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // Oracle API Endpoint
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Updating Oracle API Endpoint...'});
        Lib.verbose && Lib.log({msg: `API Endpoint: ${options.oracleApiEndpoint}`, indent: 1});
        receipt = await cryptoCardsOracle.updateApiEndpoint(options.oracleApiEndpoint, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // GUM Reserve Accounts
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        Lib.log({msg: 'Updating GUM Reserve Accounts...'});
        Lib.verbose && Lib.log({msg: `In-House Account:  ${inHouseAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Bounty Account:    ${bountyAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Marketing Account: ${marketingAccount}`, indent: 1});
        Lib.verbose && Lib.log({msg: `Exchange Account:  ${exchangeAccount}`, indent: 1});
        const accounts = [inHouseAccount, bountyAccount, marketingAccount, exchangeAccount];
        receipt = await cryptoCardsGum.setReserveAccounts(accounts, _getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;
        Lib.log({spacer: true});
        Lib.log({msg: 'Distributing initial GUM to Reserve Accounts...'});
        receipt = await cryptoCardsGum.distributeInitialGum(_getTxOptions());
        Lib.logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        //
        // Pack Prices
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        for (let i = 0; i < options.packPrices.length; i++) {
            Lib.log({msg: `Updating Pack Price[${i}]: ${Lib.fromFinneyToEther(options.packPrices[i])} ETH`});
            receipt = await cryptoCardsLib.updatePricePerPack(i, Lib.fromFinneyToWei(options.packPrices[i]), _getTxOptions());
            Lib.logTxResult(receipt);
            totalGas += receipt.receipt.gasUsed;
        }

        //
        // Promo Codes
        //
        Lib.log({separator: true});
        Lib.log({spacer: true});
        for (let i = 0; i < options.promoCodes.length; i++) {
            Lib.log({msg: `Updating PromoCode[${i}]: ${options.promoCodes[i]}`});
            receipt = await cryptoCardsLib.updatePromoCode(i, options.promoCodes[i], _getTxOptions());
            Lib.logTxResult(receipt);
            totalGas += receipt.receipt.gasUsed;
        }

        //
        // Pause the Controller
        //
        if (Lib.network !== 'local') {
            Lib.log({separator: true});
            Lib.log({spacer: true});
            Lib.log({msg: 'Pausing Controller...'});
            receipt = await cryptoCardsController.pause(_getTxOptions());
            Lib.logTxResult(receipt);
            totalGas += receipt.receipt.gasUsed;
        }

        //
        // Enable GUM Token Purchases
        //
        if (Lib.network === 'local') {
            Lib.log({separator: true});
            Lib.log({spacer: true});
            Lib.log({msg: 'Enabling GUM Token Purchases...'});
            receipt = await cryptoCardsGum.enablePurchases(_getTxOptions());
            Lib.logTxResult(receipt);
            totalGas += receipt.receipt.gasUsed;
        }


        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Deploy Complete
        Lib.log({separator: true});
        Lib.log({separator: true});

        Lib.log({spacer: true});
        Lib.log({spacer: true});

        Lib.log({msg: 'Contract Addresses:'});
        Lib.log({msg: `Controller:  ${ddCryptoCardsController.address}`, indent: 1});
        Lib.log({msg: `Treasury:    ${ddCryptoCardsTreasury.address}`, indent: 1});
        Lib.log({msg: `Oracle:      ${ddCryptoCardsOracle.address}`, indent: 1});
        Lib.log({msg: `Packs:       ${ddCryptoCardPacks.address}`, indent: 1});
        Lib.log({msg: `Cards:       ${ddCryptoCards.address}`, indent: 1});
        Lib.log({msg: `Gum:         ${ddCryptoCardsGum.address}`, indent: 1});
        Lib.log({msg: `Lib:         ${ddCryptoCardsLib.address}`, indent: 1});
        Lib.log({spacer: true});
        Lib.log({msg: 'Accounts:'});
        Lib.log({msg: `Proxy Admin: ${proxyAdmin}`, indent: 1});
        Lib.log({msg: `Owner:       ${owner}`, indent: 1});
        Lib.log({msg: `In-House:    ${inHouseAccount}`, indent: 1});
        Lib.log({msg: `Bounty:      ${bountyAccount}`, indent: 1});
        Lib.log({msg: `Marketing:   ${marketingAccount}`, indent: 1});
        Lib.log({msg: `Exchange:    ${exchangeAccount}`, indent: 1});
        Lib.log({spacer: true});
        Lib.log({msg: `Total Gas Used: ${totalGas} WEI`});
        Lib.log({msg: `Gas Price:      ${Lib.fromWeiToGwei(options.gasPrice)} GWEI`});
        Lib.log({msg: `Actual Cost:    ${Lib.fromWeiToEther(totalGas * options.gasPrice)} ETH`});

        if (Lib.network !== 'local') {
            Lib.log({spacer: true});
            Lib.log({msg: 'NOTE: Controller Contract is PAUSED!  You must unpause manually when ready!'});
            Lib.log({msg: 'NOTE: GUM Token Purchases are Disabled!  You must enable manually when ready!'});
        }

        Lib.log({spacer: true});
        Lib.log({msg: 'Initializations Complete!'});
        process.exit(0);
    }
    catch (err) {
        console.log(err);
        process.exit(1);
    }
};

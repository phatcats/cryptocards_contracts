/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2018 (c) Phat Cats, Inc.
 */
'use strict';

const _ = require('lodash');
const Web3 = require('web3');
const _web3 = new Web3(web3.currentProvider);
const { networkOptions } = require('../config');

const CryptoCards = artifacts.require("CryptoCards");
const CryptoCardPacks = artifacts.require("CryptoCardPacks");
const CryptoCardsTreasury = artifacts.require("CryptoCardsTreasury");
const CryptoCardsController = artifacts.require("CryptoCardsController");

const _inHouseAccount = process.env.IN_HOUSE_ACCOUNT;
const _verbose = (process.env.VERBOSE_LOGS === 'yes');

let _cryptoCards;
let _cryptoCardPacks;
let _cryptoCardsTreasury;
let _cryptoCardsController;

module.exports = async function(deployer, network, accounts) {
    const owner = accounts[0];
    let nonce = 0;
    let totalGas = 0;
    let receipt;

    let options = networkOptions['local'];
    if (network && typeof networkOptions[network] !== void(0)) {
        network = network.split('-')[0];
        options = networkOptions[network];
    }

    const _getTxOptions = () => {
        return {from: owner, nonce: nonce++, gasPrice: options.gasPrice};
    };

    if (_verbose) {
        _log({separator: true});
        _log({msg: `Network:   ${network}`});
        _log({msg: `Web3:      ${_web3.version}`});
        _log({msg: `Gas Price: ${_fromWeiToGwei(options.gasPrice)} GWEI`});
        _log({msg: `Owner:     ${owner}`});
        _log({separator: true});
    }

    try {
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Get Transaction Nonce
        nonce = (await _getTxCount(owner)) || 0;
        _log({msg: `Starting at Nonce: ${nonce}`});
        _log({separator: true});
        _log({spacer: true});
        _log({spacer: true});

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Contract Deployments
        _cryptoCards = await deployer.deploy(CryptoCards, _getTxOptions());
        receipt = await _getReceipt(_cryptoCards.transactionHash);
        totalGas += receipt.gasUsed;

        _cryptoCardPacks = await deployer.deploy(CryptoCardPacks, _getTxOptions());
        receipt = await _getReceipt(_cryptoCardPacks.transactionHash);
        totalGas += receipt.gasUsed;

        _cryptoCardsTreasury = await deployer.deploy(CryptoCardsTreasury, _getTxOptions());
        receipt = await _getReceipt(_cryptoCardsTreasury.transactionHash);
        totalGas += receipt.gasUsed;

        _cryptoCardsController = await deployer.deploy(CryptoCardsController, _getTxOptions());
        receipt = await _getReceipt(_cryptoCardsController.transactionHash);
        totalGas += receipt.gasUsed;

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Contract Linking & Initialization
        _log({spacer: true});
        _log({msg: 'Linking CryptoCards Contract...'});
        _verbose && _log({msg: `Packs:      ${_cryptoCardPacks.address}`, indent: 1});
        _verbose && _log({msg: `Controller: ${_cryptoCardsController.address}`, indent: 1});
        receipt = await _cryptoCards.initialize(_cryptoCardsController.address, _cryptoCardPacks.address, _getTxOptions());
        _logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        _log({msg: 'Linking CryptoCardPacks Contract...'});
        _verbose && _log({msg: `Cards:        ${_cryptoCards.address}`, indent: 1});
        _verbose && _log({msg: `Controller:   ${_cryptoCardsController.address}`, indent: 1});
        receipt = await _cryptoCardPacks.initialize(_cryptoCardsController.address, _cryptoCards.address, _getTxOptions());
        _logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        _log({msg: 'Linking CryptoCardsTreasury Contract...'});
        _verbose && _log({msg: `_inHouseAccount: ${_inHouseAccount}`, indent: 1});
        _verbose && _log({msg: `Controller:     ${_cryptoCardsController.address}`, indent: 1});
        receipt = await _cryptoCardsTreasury.initialize(_cryptoCardsController.address, _inHouseAccount, _getTxOptions());
        _logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        _log({msg: 'Linking CryptoCardsController Contract...'});
        _verbose && _log({msg: `Treasury:     ${_cryptoCardsTreasury.address}`, indent: 1});
        _verbose && _log({msg: `Packs:        ${_cryptoCardPacks.address}`, indent: 1});
        _verbose && _log({msg: `Cards:        ${_cryptoCards.address}`, indent: 1});
        receipt = await _cryptoCardsController.initialize(_cryptoCardsTreasury.address, _cryptoCardPacks.address, _cryptoCards.address, _getTxOptions());
        _logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Oracle API Endpoint
        _log({msg: 'Updating Oracle API Endpoint...'});
        _verbose && _log({msg: `Endpoint:     ${options.oracleApiEndpoint}`, indent: 1});
        receipt = await _cryptoCardsController.updateApiEndpoint(options.oracleApiEndpoint, _getTxOptions());
        _logTxResult(receipt);
        totalGas += receipt.receipt.gasUsed;

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Pack Prices
        for (let i = 0; i < options.packPrices.length; i++) {
            _log({msg: `Updating Pack Price[${i}]: ${_fromFinneyToEther(options.packPrices[i])} ETH`});
            receipt = await _cryptoCardsController.updatePricePerPack(i, _fromFinneyToWei(options.packPrices[i]), _getTxOptions());
            _logTxResult(receipt);
            totalGas += receipt.receipt.gasUsed;
        }

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Promo Codes
        for (let i = 0; i < options.promoCodes.length; i++) {
            _log({msg: `Updating PromoCode[${i}]: ${options.promoCodes[i]}`});
            receipt = await _cryptoCardsController.updatePromoCode(i, options.promoCodes[i], _getTxOptions());
            _logTxResult(receipt);
            totalGas += receipt.receipt.gasUsed;
        }

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Unpause the Controller
        if (network === 'local') {
            _log({msg: 'Unpausing Controller...'});
            receipt = await _cryptoCardsController.unpause(_getTxOptions());
            _logTxResult(receipt);
            totalGas += receipt.receipt.gasUsed;
        } else {
            _log({msg: 'NOTE: Controller Contract is PAUSED!  You must unpause manually when ready!'});
        }

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Deploy Complete
        _log({separator: true});
        _log({separator: true});

        _log({spacer: true});
        _log({spacer: true});

        _log({msg: 'Contract Addresses:'});
        _log({msg: `Treasury:   ${_cryptoCardsTreasury.address}`, indent: 1});
        _log({msg: `Packs:      ${_cryptoCardPacks.address}`, indent: 1});
        _log({msg: `Cards:      ${_cryptoCards.address}`, indent: 1});
        _log({msg: `Controller: ${_cryptoCardsController.address}`, indent: 1});
        _log({spacer: true});
        _log({msg: 'Accounts:'});
        _log({msg: `Owner:      ${owner}`, indent: 1});
        _log({msg: `In-House:   ${_inHouseAccount}`, indent: 1});
        _log({spacer: true});
        _log({msg: `Total Gas Used: ${totalGas} WEI`});
        _log({msg: `Gas Price:      ${_fromWeiToGwei(options.gasPrice)} GWEI`});
        _log({msg: `Actual Cost:    ${_fromWeiToEther(totalGas * options.gasPrice)} ETH`});

        _log({spacer: true});
        _log({msg: 'Deploy Complete!'});
    }
    catch (err) {
        console.log(err);
    }
};

const _promisify = (fn) => (...args) => new Promise((resolve, reject) => {
    fn(...args, (err, result) => {
        if (err) {
            reject(err);
        } else {
            resolve(result);
        }
    });
});

const _fromFinneyToWei = (value) => _web3.utils.toWei(value.toString(), 'finney');
const _fromWeiToGwei = (value) => _web3.utils.fromWei(value.toString(), 'gwei');
const _fromWeiToEther = (value) => _web3.utils.fromWei(value.toString(), 'ether');
const _fromFinneyToEther = (value) => _web3.utils.fromWei(_fromFinneyToWei(value), 'ether');

const _ethTxCount = _promisify(_web3.eth.getTransactionCount);
const _getTxCount = (owner) => _ethTxCount(owner);

const _ethReceipt = _promisify(_web3.eth.getTransactionReceipt);
const _getReceipt = (hash) => _ethReceipt(hash);

const _log = ({msg, indent = 0, spacer = false, separator = false}) => {
    const msgArr = [];
    if (indent > 0) {
        const indentLevel = _.times(indent, _.constant('--')).join('');
        msgArr.push(' ', indentLevel);
    } else if (spacer) {
        msgArr.push(' ');
    } else if (separator) {
        msgArr.push('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
    } else {
        msgArr.push('[Deployer]')
    }
    if (!spacer && !separator) {
        msgArr.push(msg);
    }
    console.log(msgArr.join(' '));
};

const _logTxResult = (result) => {
    if (_verbose && result.receipt) {
        _log({msg: `TX hash:      ${result.tx}`, indent: 2});
        _log({msg: `TX status:    ${result.receipt.status}`, indent: 2});
        _log({msg: `TX gas used:  ${result.receipt.gasUsed}`, indent: 2});
    } else if (result.gasUsed) {
        _log({msg: `TX gas used:  ${result.gasUsed}`, indent: 2});
    }
    _log({spacer: true});
};

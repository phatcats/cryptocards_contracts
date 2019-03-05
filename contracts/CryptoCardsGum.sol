/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2019 (c) Phat Cats, Inc.
 *
 * Contract Audits:
 *   - SmartDEC International - https://smartcontracts.smartdec.net
 *   - Callisto Security Department - https://callisto.network/
 */

pragma solidity 0.4.24;

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";

import "./CryptoCardsERC20.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsGum is Initializable, Ownable {
    CryptoCardsERC20 internal gumToken;
    address internal cryptoCardPacks;

    // [0] = In-House               (Sent to In-House Account)
    // [1] = Bounty Rewards         (Sent to Bounty-Rewards Account)
    // [2] = Marketing Rewards      (Sent to Marketing Rewards Account)
    // [3] = Exchanges              (Sent to Exchange-Handler Account)
    // [4] = Sales from Contract    (Stays in Contract, distributed via buyGum or fallback function)
    // [5] = Packs                  (Stays in Contract, distributed via giveGumWithPack function)
    address[4] internal reserveAccounts;
    uint256[6] internal reserveRatios;

    uint256 public baseSalePrice;

    uint256 public saleGumAvailable;
    uint256 public packGumAvailable;
    uint256 public saleGumSold;

    bool public purchasesEnabled;
    bool internal tokensDistributed;
    bool internal reserveAccountsSet;

    modifier onlyPacks() {
        require(msg.sender == cryptoCardPacks, "Action only allowed by Packs contract");
        _;
    }

    function initialize(address _owner) public initializer {
        Ownable.initialize(_owner);

        baseSalePrice = 40000 * (10**18); // tokens per 1 ether

        // dist = (total * ratio) / 100
        reserveRatios = [
            31,   // % of Total         930,000,000
             5,   //                    150,000,000
             5,   //                    150,000,000
            20,   //                    600,000,000
             5,   //                    150,000,000
            34    //                  1,020,000,000
        ];        //                -----------------
                  // Total            3,000,000,000
    }

    function setPacksAddress(address _packs) public onlyOwner {
        require(_packs != address(0), "Invalid address supplied");
        cryptoCardPacks = _packs;
    }

    function setGumToken(CryptoCardsERC20 _token) public onlyOwner {
        require(_token != address(0), "Invalid address supplied");
        gumToken = _token;
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function enablePurchases() public onlyOwner {
        purchasesEnabled = true;
    }

    function disablePurchases() public onlyOwner {
        purchasesEnabled = false;
    }

    function transferGumRevenueToInHouse() public onlyOwner {
        require(reserveAccounts[0] != address(0), "In-House Reserve Account is not set");
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract balance is zero");
        reserveAccounts[0].transfer(balance);
    }

    function setReserveAccounts(address[] _accounts) public onlyOwner {
        require(!reserveAccountsSet, "Reserve Accounts already set");
        require(_accounts.length == 4, "Invalid accounts supplied; must be an array of length 4");

        for (uint256 i = 0; i < 4; ++i) {
            require(_accounts[i] != address(0), "Invalid address supplied for reserve account");
            reserveAccounts[i] = _accounts[i];
        }
        reserveAccountsSet = true;
    }

    function distributeInitialGum() public onlyOwner {
        require(reserveAccountsSet, "Reserve accounts are not set");
        require(!tokensDistributed, "Tokens have already been distributed to reserve accounts");

        uint256 totalSupply = gumToken.totalSupply();
        uint256 amount;
        uint len = reserveAccounts.length;
        for (uint256 i = 0; i < len; ++i) {
            amount = totalSupply * reserveRatios[i] / 100;
            gumToken.transfer(reserveAccounts[i], amount);
        }

        saleGumAvailable = totalSupply * reserveRatios[4] / 100;
        packGumAvailable = totalSupply * reserveRatios[5] / 100;

        tokensDistributed = true;
    }

    function buyGum() public payable {
        _buyGum(msg.sender, msg.value);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return gumToken.balanceOf(_owner);
    }

    function claimPackGum(address _to, uint256 _amountOfGum) public onlyPacks returns (uint256) {
        require(_to != address(0), "Invalid address supplied");
        require(tokensDistributed, "Tokens have not yet been distributed");
        require(_amountOfGum > 0, "amountOfGum must be greater than zero");

        uint256 tokens = _amountOfGum;
        if (tokens > packGumAvailable) {
            tokens = packGumAvailable;
        }

        // Track Gum Supplies
        packGumAvailable = packGumAvailable - tokens;

        // Transfer Gum Tokens
        gumToken.transfer(_to, tokens);
        return tokens;
    }

    function _buyGum(address _to, uint256 _etherPaid) internal {
        require(purchasesEnabled, "Purchases are not enabled");
        require(tokensDistributed, "Tokens have not yet been distributed");
        require(_to != address(0), "Invalid address supplied");
        require(_etherPaid > 0, "etherPaid must be greater than zero");
        require(saleGumAvailable > 0, "No Sale-Gum available");

        // Calculate tokens to sell
        uint256 amountPaid = _etherPaid;
        uint256 tokens = amountPaid * (baseSalePrice / (10**18));
        uint256 refund = 0;

        // Sell only tokens that are available
        if (tokens > saleGumAvailable) {
            uint256 newTokens = saleGumAvailable;
            uint256 newAmount = newTokens / tokens * amountPaid;
            refund = amountPaid - newAmount;
            amountPaid = newAmount;
            tokens = newTokens;
        }

        // Track Gum Sales
        saleGumSold = saleGumSold + tokens;
        saleGumAvailable = saleGumAvailable - tokens;

        // Transfer Gum Tokens
        gumToken.transfer(_to, tokens);

        // Refund over-spend
        if (refund > 0) {
            _to.transfer(refund);
        }
    }
}

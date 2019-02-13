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
import "./CryptoCardsTreasury.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsGum is Initializable, Ownable {
    CryptoCardsERC20 internal gumToken;
    CryptoCardsTreasury internal cryptoCardsTreasury;
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
        require(msg.sender == cryptoCardPacks);
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

    function setContractAddresses(
        address _packs,
        CryptoCardsTreasury _treasury
    ) public onlyOwner {
        require(_packs != address(0));
        require(_treasury != address(0));

        cryptoCardPacks = _packs;
        cryptoCardsTreasury = _treasury;
    }

    function setPacksAddress(address _packs) public onlyOwner {
        require(_packs != address(0));
        cryptoCardPacks = _packs;
    }

    function setTreasuryAddress(CryptoCardsTreasury _treasury) public onlyOwner {
        require(_treasury != address(0));
        cryptoCardsTreasury = _treasury;
    }

    function setGumToken(CryptoCardsERC20 _token) public onlyOwner {
        require(_token != address(0));
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

    function transferToTreasury() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        cryptoCardsTreasury.deposit.value(balance)(balance, 0, address(0));
    }

    function setReserveAccounts(address[] _accounts) public onlyOwner {
        require(!reserveAccountsSet);

        for (uint256 i = 0; i < 4; ++i) {
            reserveAccounts[i] = _accounts[i];
        }
        reserveAccountsSet = true;
    }

    function distributeInitialGum() public onlyOwner {
        require(reserveAccountsSet && !tokensDistributed);

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
        require(tokensDistributed && _amountOfGum > 0);

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
        require(purchasesEnabled && tokensDistributed);
        require(_to != address(0) && _etherPaid > 0 && saleGumAvailable > 0);

        // Calculate tokens to sell
        uint256 amountPaid = _etherPaid;
        uint256 tokens = amountPaid * (baseSalePrice / (10**18));
        uint256 refund = 0;

        // Sell only tokens that are available
        if (tokens > saleGumAvailable) {
            uint256 newTokens = saleGumAvailable;
            uint256 newAmount = newTokens * (baseSalePrice / (10**18));
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

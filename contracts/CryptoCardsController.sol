/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2019 (c) Phat Cats, Inc.
 *
 * Contract Audits:
 *   - Callisto Security Department - https://callisto.network/
 */

pragma solidity 0.5.0;

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "openzeppelin-eth/contracts/lifecycle/Pausable.sol";
import "openzeppelin-eth/contracts/utils/ReentrancyGuard.sol";

import "./CryptoCardsLib.sol";
import "./CryptoCardsGum.sol";
import "./CryptoCardsTreasury.sol";
import "./CryptoCardsOracle.sol";
import "./CryptoCardsPacks.sol";
import "./CryptoCardsCards.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsController is Initializable, Ownable, Pausable, ReentrancyGuard {

    //
    // Storage
    //
    CryptoCardsTreasury internal _cryptoCardsTreasury;
    CryptoCardsOracle internal _cryptoCardsOracle;
    CryptoCardsPacks internal _cryptoCardsPacks;
    CryptoCardsCards internal _cryptoCardsCards;
    CryptoCardsGum internal _cryptoCardsGum;
    CryptoCardsLib internal _cryptoCardsLib;

    //
    // Events
    //
    event BuyNewPack(address indexed receiver, bytes16 uuid, uint256 pricePaid, address referredBy, uint256 promoCode);

    //
    // Modifiers
    //
    modifier onlyOracle() {
        require(msg.sender == address(_cryptoCardsOracle));
        _;
    }

    //
    // Initialize
    //
    function initialize(address owner) public initializer {
        Ownable.initialize(owner);
        Pausable.initialize(owner);
    }

    //
    // Public
    //

    function getVersion() public pure returns (string memory) {
        return "v2.0.0";
    }

    //
    // Public; Packs
    //
//    function packsOf(address owner) public view returns (uint256) {
//        return _cryptoCardsPacks.balanceOf(owner);
//    }
//
//    function packDataById(uint256 packId) public view returns (string memory) {
//        return _cryptoCardsPacks.packDataById(packId);
//    }

    //
    // Public; Cards
    //
//    function cardsOf(address owner) public view returns (uint256) {
//        return _cryptoCardsCards.balanceOf(owner);
//    }

//    function cardYear(uint256 tokenId) public pure returns (uint) {
//        return _cryptoCardsCards.getYear(tokenId);
//    }
//
//    function cardGeneration(uint256 tokenId) public pure returns (uint) {
//        return _cryptoCardsCards.getGeneration(tokenId);
//    }
//
//    function cardRank(uint256 tokenId) public pure returns (uint) {
//        return _cryptoCardsCards.getRank(tokenId);
//    }
//
//    function cardTypeIndicators(uint256 tokenId) public pure returns (uint, uint, uint) {
//        return _cryptoCardsCards.getTypeIndicators(tokenId);
//    }
//
//    function cardCombinedCount(uint256 tokenId) public pure returns (uint) {
//        return _cryptoCardsCards.getCombinedCount(tokenId);
//    }
//
//    function cardSpecialty(uint256 tokenId) public pure returns (uint) {
//        return _cryptoCardsCards.getSpecialty(tokenId);
//    }
//
//    function cardIssue(uint256 tokenId) public pure returns (uint) {
//        return _cryptoCardsCards.getIssue(tokenId);
//    }
//
//    function cardWrappedGum(uint256 tokenId) public pure returns (uint) {
//        return _cryptoCardsCards.getWrappedGum(tokenId);
//    }
//
//    function cardTraits(uint256 tokenId) public pure returns (uint) {
//        return _cryptoCardsCards.getTraits(tokenId);
//    }
//
//    function cardHasTrait(uint256 tokenId, uint256 trait) public pure returns (bool) {
//        return _cryptoCardsCards.hasTrait(tokenId, trait);
//    }

//    function cardTotalIssued(uint256 tokenId) public view returns (uint) {
//        return _cryptoCardsCards.getTotalIssued(tokenId);
//    }
//
//    function isCardPrinted(uint256 tokenId) public view returns (bool) {
//        return _cryptoCardsCards.isTokenPrinted(tokenId);
//    }
//
//    function canCombineCards(uint256 tokenA, uint256 tokenB) public view returns (bool) {
//        return _cryptoCardsCards.canCombine(tokenA, tokenB);
//    }
//
//    function getEarnedGum(address owner) public view returns (uint256) {
//        return _cryptoCardsCards.getEarnedGum(owner);
//    }

    //
    // Public; Gum
    //
//    function gumOf(address owner, uint flavor) public view returns (uint256) {
//        return _cryptoCardsGum.balanceOf(owner, flavor);
//    }

    //
    // Public; Lib
    //
//    function getPromoCode(uint8 index) public view returns (uint256) {
//        return _cryptoCardsLib.getPromoCode(index);
//    }
//
//    function getReferralLevel(uint8 index) public view returns (uint256) {
//        return _cryptoCardsLib.getReferralLevel(index);
//    }
//
//    function getPurchasedPackCount(address owner) public view returns (uint256) {
//        return _cryptoCardsLib.getPurchasedPackCount(owner);
//    }
//
//    function getPackPrice() public view returns (uint256) {
//        return _cryptoCardsLib.getPrice();
//    }

    //
    // Public; Treasury; Rewards
    //

//    function paidReferralBalanceOf(address account) public view returns (uint256) {
//        return _cryptoCardsTreasury.getPaidBalanceOfReferrer(account);
//    }
//
//    function unpaidReferralBalanceOf(address account) public view returns (uint256) {
//        return _cryptoCardsTreasury.getUnpaidBalanceOfReferrer(account);
//    }
//
//    function paidBountyBalanceOf(address account) public view returns (uint256) {
//        return _cryptoCardsTreasury.getPaidBalanceOfMember(account);
//    }
//
//    function unpaidBountyBalanceOf(address account) public view returns (uint256) {
//        return _cryptoCardsTreasury.getUnpaidBalanceOfMember(account);
//    }
//
//    function availableBountyBalanceOf(address account) public view returns (uint256) {
//        return _cryptoCardsTreasury.getAvailableBalanceOfMember(account);
//    }
//
//    function bountyPayoutInterval() public view returns (uint256) {
//        return _cryptoCardsTreasury.getOutsourcedPayoutInterval();
//    }
//
//    function totalBalanceOfBountyPool() public view returns (uint256) {
//        return _cryptoCardsTreasury.getTotalBalanceOfPool();
//    }
//
//    function claimEarnedGum() public returns (uint256) {
//        return _cryptoCardsGum.claimEarnedGum(msg.sender);
//    }
//
//    function claimReferralRewards() public returns (uint256) {
//        return _cryptoCardsTreasury.withdrawForReferrer(msg.sender);
//    }
//
//    function claimBountyRewards() public returns (uint256) {
//        return _cryptoCardsTreasury.withdrawForMember(msg.sender);
//    }

    //
    // Set Prices/Trades
    //

    function clearPackPrice(uint256 packId, bytes16 uuid) public whenNotPaused {
        _setPackPrice(msg.sender, packId, 0, uuid);
    }

    function updatePackPrice(uint256 packId, uint256 packPrice, bytes16 uuid) public whenNotPaused {
        _setPackPrice(msg.sender, packId, packPrice, uuid);
    }

    function clearCardPrice(uint256 cardId, bytes16 uuid) public whenNotPaused {
        _setCardPrice(msg.sender, cardId, 0, uuid);
    }

    function updateCardPrice(uint256 cardId, uint256 cardPrice, bytes16 uuid) public whenNotPaused {
        _setCardPrice(msg.sender, cardId, cardPrice, uuid);
    }

    function clearCardTradeValue(uint256 cardId, bytes16 uuid) public whenNotPaused {
        _setCardTradeValue(msg.sender, cardId, 0, new uint8[](0), new uint8[](0), uuid);
    }

    function updateCardTradeValue(uint256 cardId, uint16 cardRank, uint8[] memory cardGens, uint8[] memory cardYears, bytes16 uuid) public whenNotPaused {
        _setCardTradeValue(msg.sender, cardId, cardRank, cardGens, cardYears, uuid);
    }

    //
    // Buy/Sell/Trade/Open
    //

    function buyPackFromOwner(address payable owner, uint256 packId, bytes16 uuid) public nonReentrant whenNotPaused payable {
        require(owner != address(0) && msg.sender != owner);

        // Transfer Pack
        uint256 pricePaid = msg.value;
        uint256 packPrice = _cryptoCardsPacks.transferPackForBuyer(msg.sender, owner, packId, pricePaid, uuid);

        // Pay for Pack
        owner.transfer(packPrice);

        // Refund over-spend
        if (pricePaid > packPrice) {
            msg.sender.transfer(pricePaid - packPrice);
        }
    }

    function buyCardFromOwner(address payable owner, uint256 cardId, bytes16 uuid) public nonReentrant whenNotPaused payable {
        require(owner != address(0) && msg.sender != owner);

        // Transfer Card
        uint256 pricePaid = msg.value;
        uint256 cardPrice = _cryptoCardsCards.transferCardForBuyer(msg.sender, owner, cardId, pricePaid, uuid);

        // Pay for Card
        owner.transfer(cardPrice);

        // Refund over-spend
        if (pricePaid > cardPrice) {
            msg.sender.transfer(pricePaid - cardPrice);
        }
    }

//    function tradeCardForCard(address owner, uint256 ownerCardId, uint256 tradeCardId, bytes16 uuid) public nonReentrant whenNotPaused {
//        require(owner != address(0) && msg.sender == owner);
//
//        _cryptoCardsCards.tradeCardForCard(owner, ownerCardId, tradeCardId, uuid);
//    }

    function buyPackOfCards(address referredBy, uint256 promoCode, bytes16 uuid) public nonReentrant whenNotPaused payable {
        require(msg.sender != address(0) && _cryptoCardsOracle.isValidUuid(uuid));

        bool hasReferral = false;
        if (referredBy != address(0) && referredBy != address(this)) {
            hasReferral = true;
        }

        uint256 pricePaid = msg.value;
        uint256 cost = _cryptoCardsLib.getPricePerPack(promoCode, hasReferral);
        require(pricePaid >= cost);

        // Get Pack of Cards and Assign to Receiver
        uint256 oracleGasReserve = _cryptoCardsOracle.getGasReserve();
        _cryptoCardsOracle.getNewPack.value(oracleGasReserve)(msg.sender, oracleGasReserve, uuid);

        // Distribute Payment for Pack
        uint256 netAmount = cost - oracleGasReserve;
        uint256 forReferrer = 0;
        if (hasReferral) {
            forReferrer = _cryptoCardsLib.getAmountForReferrer(referredBy, cost);
        }

        // Deposit Funds to Treasury
        _cryptoCardsTreasury.deposit.value(netAmount)(netAmount, forReferrer, referredBy);

        // Emit Event to DApp
        emit BuyNewPack(msg.sender, uuid, pricePaid, referredBy, promoCode);
        _cryptoCardsLib.incrementPurchasedPackCount(msg.sender, 1);

        // Refund over-spend
        if (pricePaid > cost) {
            msg.sender.transfer(pricePaid - cost);
        }
    }

    //
    // Advanced Functions
    //

//    function openPack(uint256 packId, bytes16 uuid) public whenNotPaused {
//        _cryptoCardsPacks.openPack(msg.sender, packId, uuid);
//    }
//
//    function combineCards(uint256 cardA, uint256 cardB) public whenNotPaused returns (uint256) {
//        return _cryptoCardsCards.combineCards(msg.sender, cardA, cardB);
//    }
//
//    function printCards(uint256[] memory cardIds) public whenNotPaused {
//        _cryptoCardsCards.printCards(msg.sender, cardIds);
//    }
//
//    function meltCards(uint256[] memory cardIds) public whenNotPaused {
//        _cryptoCardsCards.meltCards(msg.sender, cardIds);
//    }

    //
    // Only Owner
    //

    function setContractAddresses(
        CryptoCardsOracle oracle,
        CryptoCardsCards cards,
        CryptoCardsPacks packs,
        CryptoCardsTreasury treasury,
        CryptoCardsGum gum,
        CryptoCardsLib lib
    ) public onlyOwner {
        require(address(oracle) != address(0));
        require(address(cards) != address(0));
        require(address(packs) != address(0));
        require(address(treasury) != address(0));
        require(address(gum) != address(0));
        require(address(lib) != address(0));

        _cryptoCardsOracle = oracle;
        _cryptoCardsCards = cards;
        _cryptoCardsPacks = packs;
        _cryptoCardsTreasury = treasury;
        _cryptoCardsGum = gum;
        _cryptoCardsLib = lib;
    }

    //    function contractBalance() public view returns (uint256) {
    //        return address(this).balance;
    //    }
    //
    //    function transferToTreasury() public onlyOwner {
    //        uint256 balance = address(this).balance;
    //        require(balance > 0);
    //        _cryptoCardsTreasury.deposit.value(balance)(balance, 0, address(0));
    //    }

    //
    // Private
    //

    function _setPackPrice(address owner, uint256 packId, uint256 packPrice, bytes16 uuid) internal {
        _cryptoCardsPacks.updatePackPrice(owner, packId, packPrice, uuid);
    }

    function _setCardPrice(address owner, uint256 cardId, uint256 cardPrice, bytes16 uuid) internal {
        _cryptoCardsCards.updateCardPrice(owner, cardId, cardPrice, uuid);
    }

    function _setCardTradeValue(address owner, uint256 cardId, uint16 cardRank, uint8[] memory cardGens, uint8[] memory cardYears, bytes16 uuid) internal {
        _cryptoCardsCards.updateCardTradeValue(owner, cardId, cardRank, cardGens, cardYears, uuid);
    }
}

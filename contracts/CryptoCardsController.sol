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

pragma solidity 0.5.2;

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "openzeppelin-eth/contracts/lifecycle/Pausable.sol";
import "openzeppelin-eth/contracts/utils/ReentrancyGuard.sol";

import "./CryptoCardsLib.sol";
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
    CryptoCardsLib internal _cryptoCardsLib;

    //
    // Events
    //
    event BuyNewPack(address indexed receiver, bytes16 uuid, uint256 pricePaid, address referredBy, uint256 promoCode);

    //
    // Modifiers
    //
    modifier onlyOracle() {
        require(msg.sender == address(_cryptoCardsOracle), "Oracle Only");
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
        return "v2.2.0";
    }

    //
    // Buy/Sell/Trade
    //

    function buyPackOfCards(address referredBy, uint256 promoCode, bytes16 uuid) public nonReentrant whenNotPaused payable {
        require(msg.sender != address(0) && _cryptoCardsOracle.isValidUuid(uuid), "Invalid params");

        bool hasReferral = false;
        if (referredBy != address(0) && referredBy != address(this)) {
            hasReferral = true;
        }

        uint256 pricePaid = msg.value;
        uint256 cost = _cryptoCardsLib.getPricePerPack(promoCode, hasReferral);
        require(pricePaid >= cost, "Insufficient funds for pack");

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

    function buyPackFromOwner(address payable owner, uint256 packId, bytes16 uuid) public nonReentrant whenNotPaused payable {
        require(owner != address(0) && msg.sender != owner, "Invalid owner");

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

    function buyCardFromOwner(address cardOwner, uint256 cardId, bytes16 uuid) public nonReentrant whenNotPaused payable {
        require(cardOwner != address(0) && msg.sender != cardOwner, "Invalid card owner");
        address payable ownerWallet = address(uint160(cardOwner));

        // Transfer Card
        uint256 pricePaid = msg.value;
        uint256 cardPrice = _cryptoCardsCards.transferCardForBuyer(msg.sender, cardOwner, cardId, pricePaid, uuid);

        // Pay for Card
        ownerWallet.transfer(cardPrice);

        // Refund over-spend
        if (pricePaid > cardPrice) {
            msg.sender.transfer(pricePaid - cardPrice);
        }
    }

    function tradeCardForCard(address owner, uint256 ownerCardId, uint256 tradeCardId, bytes16 uuid) public nonReentrant whenNotPaused {
        require(owner != address(0) && msg.sender == owner, "Invalid owner");

        _cryptoCardsCards.tradeCardForCard(owner, ownerCardId, tradeCardId, uuid);
    }

    //
    // Only Owner
    //

    function setContractAddresses(
        CryptoCardsOracle oracle,
        CryptoCardsCards cards,
        CryptoCardsPacks packs,
        CryptoCardsTreasury treasury,
        CryptoCardsLib lib
    ) public onlyOwner {
        require(address(oracle) != address(0), "Invalid oracle address");
        require(address(cards) != address(0), "Invalid cards address");
        require(address(packs) != address(0), "Invalid packs address");
        require(address(treasury) != address(0), "Invalid treasury address");
        require(address(lib) != address(0), "Invalid lib address");

        _cryptoCardsOracle = oracle;
        _cryptoCardsCards = cards;
        _cryptoCardsPacks = packs;
        _cryptoCardsTreasury = treasury;
        _cryptoCardsLib = lib;
    }
}

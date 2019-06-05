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

import "./strings.sol";

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";

import "./CryptoCardsCardToken.sol";
import "./CryptoCardsLib.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsCards is Initializable, Ownable {
    using strings for *;
    uint public constant MAX_TRADE_RANKS = 10;

    //
    // Storage
    //
    CryptoCardsCardToken internal _cardToken;
    CryptoCardsLib internal _lib;

    // Contract Reference Addresses
    address internal _controller;

    // Mapping from token ID to sell-value
    mapping(uint256 => uint256) internal _cardSalePriceById;

    // Mapping from Token ID to Allowed Trade Values
    mapping(uint256 => uint16) internal _cardAllowedTradeRank;  // tokenId => cardRank  (ONE-for-ONE TRADES ONLY)
    mapping(uint256 => uint8) internal _cardAllowedTradeGens; // tokenId => 0 = Any, > 0 = Bits == Gen + 1
    mapping(uint256 => uint8) internal _cardAllowedTradeYears; // tokenId => 0 = Any, > 0 = Bits == Year + 1

    //
    // Events
    //
    event CardPriceSet      (address indexed owner, bytes16 uuid, uint256 cardId, uint256 price);
    event CardTradeValueSet (address indexed owner, bytes16 uuid, uint256 cardId, uint16 cardRank, uint8[] cardGens, uint8[] cardYears);
//    event CardTradeValueSet (address indexed owner, bytes16 uuid, uint256 cardId, uint16[] memory cardRanks, uint8[] memory cardGens, uint8[] memory cardYears);
    event CardSale          (address indexed owner, address indexed receiver, bytes16 uuid, uint256 cardId, uint256 price);
    event CardTrade         (address indexed owner, address indexed receiver, bytes16 uuid, uint256 ownerCardId, uint256 tradeCardId);

    //
    // Modifiers
    //
    modifier onlyController() {
        require(msg.sender == _controller, "Action only allowed by Controller contract");
        _;
    }

    modifier onlyUnprintedCards(uint256 cardId) {
        require(_cardToken.isTokenPrinted(cardId) != true, "Action only allowed on Unprinted Cards");
        _;
    }

    //
    // Initialize
    //
    function initialize(address owner) public initializer {
        Ownable.initialize(owner);
    }

    //
    // Public
    //

    function totalMintedCards() public view returns (uint256) {
        return _cardToken.totalSupply();
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _cardToken.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _cardToken.ownerOf(tokenId);
    }

//    function getYear(uint256 tokenId) public pure returns (uint) {
//        return _cardToken.getYear(tokenId);
//    }
//
//    function getGeneration(uint256 tokenId) public pure returns (uint) {
//        return _cardToken.getGeneration(tokenId);
//    }
//
//    function getRank(uint256 tokenId) public pure returns (uint) {
//        return _cardToken.getRank(tokenId);
//    }
//
//    function getTypeIndicators(uint256 tokenId) public pure returns (uint, uint, uint) {
//        return _cardToken.getTypeIndicators(tokenId);
//    }
//
//    function getCombinedCount(uint256 tokenId) public pure returns (uint) {
//        return _cardToken.getCombinedCount(tokenId);
//    }
//
//    function getSpecialty(uint256 tokenId) public pure returns (uint) {
//        return _cardToken.getSpecialty(tokenId);
//    }
//
//    function getIssue(uint256 tokenId) public pure returns (uint) {
//        return _cardToken.getIssue(tokenId);
//    }
//
//    function getWrappedGum(uint256 tokenId) public pure returns (uint) {
//        return _cardToken.getWrappedGum(tokenId);
//    }
//
//    function getTraits(uint256 tokenId) public pure returns (uint) {
//        return _cardToken.getTraits(tokenId);
//    }
//
//    function hasTrait(uint256 tokenId, uint256 trait) public pure returns (bool) {
//        return _cardToken.hasTrait(tokenId, trait);
//    }

    function getTotalIssued(uint256 tokenId) public view returns (uint) {
        return _cardToken.getTotalIssued(tokenId);
    }

    function isTokenPrinted(uint256 tokenId) public view returns (bool) {
        return _cardToken.isTokenPrinted(tokenId);
    }

    function canCombine(uint256 tokenA, uint256 tokenB) public view returns (bool) {
        return _cardToken.canCombine(tokenA, tokenB);
    }

    function getEarnedGum(address owner) public view returns (uint256) {
        return _cardToken.getEarnedGum(owner);
    }

    //
    // Only Owner
    //

    function setContractController(address controller) public onlyOwner {
        require(controller != address(0), "Invalid address supplied");
        _controller = controller;
    }

    function setCryptoCardsCardToken(CryptoCardsCardToken token) public onlyOwner {
        require(address(token) != address(0), "Invalid address supplied");
        _cardToken = token;
    }

    function setLibAddress(CryptoCardsLib lib) public onlyOwner {
        require(address(lib) != address(0), "Invalid address supplied");
        _lib = lib;
    }

    //
    // Only Controller Contract
    //

    function updateCardPrice(address owner, uint256 cardId, uint256 cardPrice, bytes16 uuid)
        public
        onlyController
        onlyUnprintedCards(cardId)
    {
        address cardOwner = _cardToken.ownerOf(cardId); // will revert if owner == address(0)
        require(owner == cardOwner, "Invalid owner supplied or owner is not card-owner");
        _cardSalePriceById[cardId] = cardPrice;
        emit CardPriceSet(owner, uuid, cardId, cardPrice);
    }

    function updateCardTradeValue(address owner, uint256 cardId, uint16 cardRank, uint8[] memory cardGens, uint8[] memory cardYears, bytes16 uuid)
        public
        onlyController
        onlyUnprintedCards(cardId)
    {
        address cardOwner = _cardToken.ownerOf(cardId); // will revert if owner == address(0)
        require(owner == cardOwner, "Invalid owner supplied or owner is not card-owner");

        // cardRanks are 1-based, but our storage is 0-based
        _cardAllowedTradeRank[cardId] = cardRank-1;

        // Add New Trade Values
        for (uint i = 0; i < cardGens.length; i++) {
            _cardAllowedTradeGens[cardId] = cardGens[i];
            _cardAllowedTradeYears[cardId] = cardYears[i];
        }
        emit CardTradeValueSet(cardOwner, uuid, cardId, cardRank, cardGens, cardYears);
    }

    function transferCardForBuyer(address receiver, address owner, uint256 cardId, uint256 pricePaid, bytes16 uuid)
        public
        onlyController
        onlyUnprintedCards(cardId)
        returns (uint256)
    {
        address cardOwner = _cardToken.ownerOf(cardId); // will revert if owner == address(0)
        require(owner == cardOwner , "Invalid owner supplied or owner is not card-owner");
        require(receiver != cardOwner, "Cannot transfer card to self");

        uint256 cardPrice = _cardSalePriceById[cardId];
        require(cardPrice > 0, "Card is not for sale");
        require(pricePaid >= cardPrice, "Card price is greater than the price paid");

        _transferCard(cardOwner, receiver, cardId);

        emit CardSale(cardOwner, receiver, uuid, cardId, cardPrice);

        return cardPrice;
    }

    function tradeCardForCard(address owner, uint256 ownerCardId, uint256 desiredCardId, bytes16 uuid)
        public
        onlyController
        onlyUnprintedCards(ownerCardId)
        onlyUnprintedCards(desiredCardId)
    {
        address ownerCardRealOwner = _cardToken.ownerOf(ownerCardId); // will revert if owner == address(0)
        address desiredCardRealOwner = _cardToken.ownerOf(desiredCardId); // will revert if owner == address(0)
        require(ownerCardRealOwner == owner, "owner supplied is not real owner of card");

        // Validate Trade
        _validateTradeValue(ownerCardId, desiredCardId);

        // Trade Cards
        _transferCard(ownerCardRealOwner, desiredCardRealOwner, ownerCardId); // initiator gives first
        _transferCard(desiredCardRealOwner, ownerCardRealOwner, desiredCardId);

        emit CardTrade(owner, desiredCardRealOwner, uuid, ownerCardId, desiredCardId);
    }

    function printCards(address owner, uint256[] memory cardIds)
        public
        onlyController
    {
        // Mark Cards as Printed
        for (uint i = 0; i < cardIds.length; i++) {
            if (_cardToken.ownerOf(cardIds[i]) == owner) {
                _resetCardValue(cardIds[i]);
                _cardToken.printFor(owner, cardIds[i]);
            }
        }
    }

    function combineCards(address owner, uint256 tokenA, uint256 tokenB)
        public
        onlyController
        returns (uint256)
    {
        return _cardToken.combineFor(owner, tokenA, tokenB);
    }

    function meltCards(address owner, uint256[] memory cardIds)
        public
        onlyController
    {
        // Melt Cards (Burn and claim underlying assets)
        for (uint i = 0; i < cardIds.length; i++) {
            _resetCardValue(cardIds[i]);
            _cardToken.meltFor(owner, cardIds[i]);
        }
    }

    //
    // Private
    //

    function _transferCard(address from, address to, uint256 cardId) internal {
        require(from != address(0), "Invalid from address supplied");
        require(to != address(0), "Invalid to address supplied");

        _resetCardValue(cardId);
        _cardToken.tokenTransfer(from, to, cardId);
    }

    function _resetCardValue(uint256 cardId) internal {
        _cardAllowedTradeRank[cardId] = 0;
        _cardAllowedTradeGens[cardId] = 0;
        _cardAllowedTradeYears[cardId] = 0;
        _cardSalePriceById[cardId] = 0;
    }

    function _validateTradeValue(uint256 ownerCardId, uint256 desiredCardId) internal view {
        (uint oY, uint oG, uint oR) = _cardToken.getTypeIndicators(ownerCardId);

        // Validate Rank (ONE-for-ONE TRADES ONLY)
        require(_cardAllowedTradeRank[desiredCardId] == oR, "Owner card cannot be traded for desired card");

        // Validate Generation
        if (_cardAllowedTradeGens[desiredCardId] > 0) { // If Not Any Gen
            require(_cardAllowedTradeGens[desiredCardId] | (oG + 1) > 0, "Owner card does not match required generation of desired card");
        }

        // Validate Year
        if (_cardAllowedTradeYears[desiredCardId] > 0) { // If Not Any Year
            require(_cardAllowedTradeYears[desiredCardId] | (oY + 1) > 0, "Owner card does not match required year of desired card");
        }
    }
}

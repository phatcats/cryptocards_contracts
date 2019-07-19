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

import "./CryptoCardsCardToken.sol";
import "./CryptoCardsGum.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsCards is Initializable, Ownable {
    uint public constant MAX_TRADE_RANKS = 10;

    //
    // Storage
    //
    CryptoCardsCardToken internal _cardToken;
    CryptoCardsGum internal _gum;

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

    function getTotalIssued(uint256 tokenId) public view returns (uint) {
        return _cardToken.getTotalIssued(tokenId);
    }

    function isTokenPrinted(uint256 tokenId) public view returns (bool) {
        return _cardToken.isTokenPrinted(tokenId);
    }

    function canCombine(uint256 tokenA, uint256 tokenB) public view returns (bool) {
        return _cardToken.canCombine(tokenA, tokenB);
    }

    function combineCards(uint256 tokenA, uint256 tokenB) public returns (uint256) {
        uint256 newTokenId = _cardToken.combineFor(msg.sender, tokenA, tokenB);
        _resetCardValue(tokenA);
        _resetCardValue(tokenB);
        return newTokenId;
    }

    function meltCard(uint256 tokenId) public {
        uint wrappedGum = _cardToken.meltFor(msg.sender, tokenId);
        _resetCardValue(tokenId);
        _gum.transferCardGum(msg.sender, wrappedGum);
    }

    function updateCardPrice(uint256 cardId, uint256 cardPrice, bytes16 uuid)
        public
        onlyUnprintedCards(cardId)
    {
        address cardOwner = _cardToken.ownerOf(cardId); // will revert if owner == address(0)
        require(msg.sender == cardOwner, "Invalid owner supplied or owner is not card-owner");
        _cardSalePriceById[cardId] = cardPrice;
        emit CardPriceSet(cardOwner, uuid, cardId, cardPrice);
    }

    function updateCardTradeValue(uint256 cardId, uint16 cardRank, uint8[] memory cardGens, uint8[] memory cardYears, bytes16 uuid)
        public
        onlyUnprintedCards(cardId)
    {
        address cardOwner = _cardToken.ownerOf(cardId); // will revert if owner == address(0)
        require(msg.sender == cardOwner, "Invalid owner supplied or owner is not card-owner");

        // cardRanks are 1-based, but our storage is 0-based
        _cardAllowedTradeRank[cardId] = cardRank-1;

        // Add New Trade Values
        for (uint i = 0; i < cardGens.length; i++) {
            _cardAllowedTradeGens[cardId] = cardGens[i];
            _cardAllowedTradeYears[cardId] = cardYears[i];
        }
        emit CardTradeValueSet(cardOwner, uuid, cardId, cardRank, cardGens, cardYears);
    }

    //
    // Only Owner
    //

    function setContractController(address controller) public onlyOwner {
        require(controller != address(0), "Invalid address supplied");
        _controller = controller;
    }

    function setGumAddress(CryptoCardsGum gum) public onlyOwner {
        require(address(gum) != address(0), "Invalid address supplied");
        _gum = gum;
    }

    function setCryptoCardsCardToken(CryptoCardsCardToken token) public onlyOwner {
        require(address(token) != address(0), "Invalid address supplied");
        _cardToken = token;
    }

    //
    // Only Controller Contract
    //

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

    function printCard(uint256 tokenId) public onlyController {
        uint wrappedGum = _cardToken.printFor(msg.sender, tokenId);
        _gum.transferCardGum(msg.sender, wrappedGum);
    }

//    function printCards(address owner, uint256[] memory cardIds)
//        public
//        onlyController
//    {
//        // Mark Cards as Printed
//        for (uint i = 0; i < cardIds.length; i++) {
//            if (_cardToken.ownerOf(cardIds[i]) == owner) {
//                _resetCardValue(cardIds[i]);
//                _cardToken.printFor(owner, cardIds[i]);
//            }
//        }
//    }

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

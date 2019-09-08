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

    mapping(uint256 => uint256[]) internal _cardAllowedTradeRanks;
    mapping(uint256 => uint256[]) internal _cardAllowedTradeGens;
    mapping(uint256 => uint256[]) internal _cardAllowedTradeYears;

    //
    // Events
    //
    event CardPriceSet      (address indexed owner, bytes16 uuid, uint256 cardId, uint256 price);
    event CardTradeValueSet (address indexed owner, bytes16 uuid, uint256 cardId, uint256[] cardRanks, uint256[] cardGens, uint256[] cardYears);
    event CardSale          (address indexed owner, address indexed receiver, bytes16 uuid, uint256 cardId, uint256 price);
    event CardTrade         (address indexed owner, address indexed receiver, bytes16 uuid, uint256 ownerCardId, uint256 tradeCardId);

    //
    // Modifiers
    //
    modifier onlyController() {
        require(msg.sender == _controller, "Action only allowed by Controller contract");
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

    function getSalePrice(uint256 tokenId) public view returns (uint256) {
        return _cardSalePriceById[tokenId];
    }

    function isTokenPrinted(uint256 tokenId) public view returns (bool) {
        return _cardToken.isTokenPrinted(tokenId);
    }

    function canCombine(uint256 tokenA, uint256 tokenB) public view returns (bool) {
        return _cardToken.canCombine(tokenA, tokenB);
    }

    function combineCards(uint256 tokenA, uint256 tokenB, uint newIssue, bytes16 uuid) public returns (uint256) {
        uint256 newTokenId = _cardToken.combineFor(msg.sender, tokenA, tokenB, newIssue, uuid);
        _resetCardValue(tokenA);
        _resetCardValue(tokenB);
        return newTokenId;
    }

    function meltCard(uint256 tokenId, bytes16 uuid) public {
        uint wrappedGum = _cardToken.meltFor(msg.sender, tokenId, uuid);
        _resetCardValue(tokenId);
        _gum.transferCardGum(msg.sender, wrappedGum);
    }

    function updateCardPrice(uint256 cardId, uint256 cardPrice, bytes16 uuid)
        public
    {
        address cardOwner = _cardToken.ownerOf(cardId); // will revert if owner == address(0)
        require(msg.sender == cardOwner, "Invalid owner supplied or owner is not card-owner");
        _cardSalePriceById[cardId] = cardPrice;
        emit CardPriceSet(cardOwner, uuid, cardId, cardPrice);
    }

    function updateCardTradeValue(uint256 cardId, uint256[] memory cardRanks, uint256[] memory cardGens, uint256[] memory cardYears, bytes16 uuid)
        public
    {
        address cardOwner = _cardToken.ownerOf(cardId); // will revert if owner == address(0)
        require(msg.sender == cardOwner, "Invalid owner supplied or owner is not card-owner");

        delete _cardAllowedTradeRanks[cardId];
        delete _cardAllowedTradeGens[cardId];
        delete _cardAllowedTradeYears[cardId];

        uint i;
        uint n = cardRanks.length;
        for (i = 0; i < n; i++) {
            _cardAllowedTradeRanks[cardId].push(cardRanks[i]);
        }
        n = cardGens.length;
        for (i = 0; i < n; i++) {
            _cardAllowedTradeGens[cardId].push(cardGens[i]);
        }
        n = cardYears.length;
        for (i = 0; i < n; i++) {
            _cardAllowedTradeYears[cardId].push(cardYears[i]);
        }

        emit CardTradeValueSet(cardOwner, uuid, cardId, cardRanks, cardGens, cardYears);
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
        returns (uint256)
    {
        address cardOwner = _cardToken.ownerOf(cardId); // will revert if owner == address(0)
        require(owner == cardOwner, "Invalid owner supplied or owner is not card-owner");
        require(receiver != address(0) && receiver != cardOwner, "Invalid receiver address supplied");

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

    function printCard(uint256 tokenId, bytes16 uuid) public onlyController {
        _cardToken.printFor(msg.sender, tokenId, uuid);
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
        _resetCardValue(cardId);
        _cardToken.tokenTransfer(from, to, cardId);
    }

    function _resetCardValue(uint256 cardId) internal {
        delete _cardAllowedTradeRanks[cardId];
        delete _cardAllowedTradeGens[cardId];
        delete _cardAllowedTradeYears[cardId];
        _cardSalePriceById[cardId] = 0;
    }

    function _validateTradeValue(uint256 ownerCardId, uint256 desiredCardId) internal view {
        (uint oY, uint oG, uint oR) = _cardToken.getTypeIndicators(ownerCardId);

        require(_isValidTradeValue(_cardAllowedTradeRanks[desiredCardId], oR, false), "Invalid Rank for Trade");
        require(_isValidTradeValue(_cardAllowedTradeGens[desiredCardId], oG, true), "Invalid Generation for Trade");
        require(_isValidTradeValue(_cardAllowedTradeYears[desiredCardId], oY, true), "Invalid Year for Trade");
    }

    function _isValidTradeValue(uint256[] memory allowedTradeValues, uint tradeValue, bool allowAny) internal pure returns (bool) {
        uint n = allowedTradeValues.length;
        if (n == 0) { return allowAny; }

        bool isValid = false;
        for (uint i = 0; i < n; i++) {
            if (allowedTradeValues[i] == uint256(tradeValue)) {
                isValid = true;
                break;
            }
        }
        return isValid;
    }
}

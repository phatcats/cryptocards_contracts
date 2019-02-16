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

import "./strings.sol";

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";

import "./CryptoCardsLib.sol";
import "./CryptoCardsERC721.sol";
import "./CryptoCardPacks.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCards is Initializable, Ownable {
    using strings for *;

    CryptoCardsERC721 internal token;
    CryptoCardsLib internal lib;
    CryptoCardPacks internal packs;

    // Info-URI Endpoint
    string internal endpoint;

    // Contract Reference Addresses
    address internal cryptoCardsController;

    // Mapping from token ID to sell-value
    mapping(uint256 => uint256) internal cardSalePriceById;

    // Mapping from token ID to card-data
    mapping(uint256 => string) internal cardHashByTokenId;
    mapping(uint256 => uint16) internal cardIssueByTokenId;
    mapping(uint256 => uint8) internal cardIndexByTokenId;
    mapping(uint256 => uint8) internal cardGenByTokenId;

    // Mapping from Token ID to Allowed Trade Values
    mapping(uint256 => bool[256]) internal cardAllowedTradesByTokenId;  // tokenId => bool[cardIndex]
    mapping(uint256 => bool[4]) internal cardAllowedTradeGensByTokenId; // [0] = Any, [1, 2, 3] = Gen

    modifier onlyController() {
        require(msg.sender == cryptoCardsController);
        _;
    }

    modifier onlyPacks() {
        require(msg.sender == address(packs));
        _;
    }

    modifier onlyUnprintedCards(uint256 _cardId) {
        require(token.isTokenFrozen(_cardId) != true);
        _;
    }

    function initialize(address _owner) public initializer {
        Ownable.initialize(_owner);
        endpoint = "https://crypto-cards.io/card-info/";
    }

    function setContractAddresses(
        address _controller,
        CryptoCardPacks _packs,
        CryptoCardsLib _lib
    ) public onlyOwner {
        require(_controller != address(0));
        require(_packs != address(0));
        require(_lib != address(0));

        cryptoCardsController = _controller;
        packs = _packs;
        lib = _lib;
    }

    function setContractController(address _controller) public onlyOwner {
        require(_controller != address(0));
        cryptoCardsController = _controller;
    }

    function setPacksAddress(CryptoCardPacks _packs) public onlyOwner {
        require(_packs != address(0));
        packs = _packs;
    }

    function setErc721Token(CryptoCardsERC721 _token) public onlyOwner {
        require(_token != address(0));
        token = _token;
    }

    function setLibAddress(CryptoCardsLib _lib) public onlyOwner {
        require(_lib != address(0));
        lib = _lib;
    }

    function updateEndpoint(string _endpoint) public onlyOwner {
        endpoint = _endpoint;
    }

    function totalMintedCards() public view returns (uint256) {
        return token.totalSupply();
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return token.balanceOf(_owner);
    }

    function cardHashById(uint256 _cardId) public view returns (string) {
        require(_cardId >= 0 && _cardId < token.totalSupply());
        return cardHashByTokenId[_cardId];
    }

    function cardIssueById(uint256 _cardId) public view returns (uint16) {
        require(_cardId >= 0 && _cardId < token.totalSupply());
        return cardIssueByTokenId[_cardId];
    }

    function cardIndexById(uint256 _cardId) public view returns (uint8) {
        require(_cardId >= 0 && _cardId < token.totalSupply());
        return cardIndexByTokenId[_cardId];
    }

    function cardGenById(uint256 _cardId) public view returns (uint8) {
        require(_cardId >= 0 && _cardId < token.totalSupply());
        return cardGenByTokenId[_cardId];
    }

    function isCardPrinted(uint256 _cardId) public view returns (bool) {
        return token.isTokenFrozen(_cardId);
    }

    function updateCardPrice(address _owner, uint256 _cardId, uint256 _cardPrice) public onlyController onlyUnprintedCards(_cardId) {
        require(_cardId >= 0 && _cardId < token.totalSupply());
        address cardOwner = token.ownerOf(_cardId);
        require(cardOwner != address(0) && _owner == cardOwner);
        cardSalePriceById[_cardId] = _cardPrice;
    }

    function updateCardTradeValue(address _owner, uint256 _cardId, uint8[] _cardValues, uint8[] _cardGens) public onlyController onlyUnprintedCards(_cardId) {
        require(_cardId >= 0 && _cardId < token.totalSupply());
        address cardOwner = token.ownerOf(_cardId);
        require(cardOwner != address(0) && _owner == cardOwner);

        // Clear Previous Trade Values
        delete cardAllowedTradesByTokenId[_cardId];
        delete cardAllowedTradeGensByTokenId[_cardId];

        // Add New Trade Values
        uint i;
        uint vn = _cardValues.length;
        uint gn = _cardGens.length;
        for (i = 0; i < vn; i++) {
            // _cardValues are 1-based, but our storage is 0-based
            cardAllowedTradesByTokenId[_cardId][ _cardValues[i]-1 ] = true;
        }
        if (gn > 0) {
            for (i = 0; i < gn; i++) {
                cardAllowedTradeGensByTokenId[_cardId][ _cardGens[i] ] = true;
            }
        } else {
            if (vn > 0) {
                cardAllowedTradeGensByTokenId[_cardId][0] = true; // Any Generation
            }
        }
    }

    function transferCardForBuyer(address _receiver, address _owner, uint256 _cardId, uint256 _pricePaid) public onlyController onlyUnprintedCards(_cardId) returns (uint256) {
        require(_cardId >= 0 && _cardId < token.totalSupply());
        address cardOwner = token.ownerOf(_cardId);
        require(cardOwner != address(0) && _owner == cardOwner && _receiver != cardOwner);

        uint256 cardPrice = cardSalePriceById[_cardId];
        require(cardPrice > 0 && _pricePaid >= cardPrice);

        transferCard(cardOwner, _receiver, _cardId);

        return cardPrice;
    }

    function tradeCardForCard(address _owner, uint256 _ownerCardId, uint256 _tradeCardId) public onlyController onlyUnprintedCards(_ownerCardId) returns (address) {
        require(_tradeCardId >= 0 && _tradeCardId < token.totalSupply() && _ownerCardId >= 0 && _ownerCardId < token.totalSupply());
        address ownerCardRealOwner = token.ownerOf(_ownerCardId);
        address tradeCardRealOwner = token.ownerOf(_tradeCardId);
        require(ownerCardRealOwner == _owner);
        require(tradeCardRealOwner != address(0));

        // Validate Trade
        validateTradeValue(_ownerCardId, _tradeCardId);

        // Trade Cards
        transferCard(ownerCardRealOwner, tradeCardRealOwner, _ownerCardId); // initiator gives first
        transferCard(tradeCardRealOwner, ownerCardRealOwner, _tradeCardId);
        return tradeCardRealOwner;
    }

    function mintCard(address _to, string _cardData) public onlyPacks returns (uint256) {
        uint cardId = token.totalSupply();
        strings.slice memory cardDataSlice = _cardData.toSlice();
        token.mintWithTokenURI(_to, cardId, endpoint.toSlice().concat(cardDataSlice));

        uint256 cardData = lib.bytesToUint(lib.fromHex(_cardData));
        cardHashByTokenId[cardId] = _cardData;
        cardIssueByTokenId[cardId] = uint16(lib.readBits(cardData, 0, 22));
        cardIndexByTokenId[cardId] = uint8(lib.readBits(cardData, 22, 8));
        cardGenByTokenId[cardId] = uint8(lib.readBits(cardData, 30, 2));
        return cardId;
    }

    function freezePrintedCards(address _owner, uint256[] _cardIds) public onlyController {
        // Mark Cards as Printed
        uint n = _cardIds.length;
        for (uint i = 0; i < n; i++) {
            if (token.ownerOf(_cardIds[i]) == _owner) {
                resetCardValue(_cardIds[i]);
                token.freezeToken(_cardIds[i]);
            }
        }
    }

    function transferCard(address _from, address _to, uint256 _cardId) internal {
        require(_from != address(0));
        require(_to != address(0));

        resetCardValue(_cardId);
        token.tokenTransfer(_from, _to, _cardId);
    }

    function resetCardValue(uint256 _cardId) internal {
        cardSalePriceById[_cardId] = 0;
        delete cardAllowedTradesByTokenId[_cardId];
        delete cardAllowedTradeGensByTokenId[_cardId];
    }

    function validateTradeValue(uint256 _ownerCardId, uint256 _tradeCardId) internal view {
        uint8 ownerCardIndex = cardIndexByTokenId[_ownerCardId];
        uint8 ownerCardGen = (cardGenByTokenId[_ownerCardId] + 1);

        require( cardAllowedTradesByTokenId[_tradeCardId][ownerCardIndex] == true );
        if (cardAllowedTradeGensByTokenId[_tradeCardId][0] != true) { // If Not Any Gen
            require( cardAllowedTradeGensByTokenId[_tradeCardId][ownerCardGen] == true );
        }
    }
}

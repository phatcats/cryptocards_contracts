/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2018 (c) Phat Cats, Inc.
 */

pragma solidity 0.4.24;

import "./Helpers.sol";
import "./strings.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./pausable.sol";
import "./erc721.sol";


/**
 * @title Crypto-Cards Card Token
 * ERC721-compliant token representing individual Cards
 */
contract CryptoCards is ERC721Token, Ownable, Helpers {
    using SafeMath for uint256;
    using strings for *;

    struct Card {
        uint16 issue;  // 1-based
        uint8 index;   // 0-based
        uint8 gen;     // 0-based
        string hash;
    }
    struct TradeValue {
        uint8 index;  // 1-based; 0 = not for trade
        uint8 gen;    // 1-based; 0 = any generation
    }

    // Info-URI Endpoint
    string internal endpoint = "https://crypto-cards.io/card-info/";

    // Minted Cards Count
    uint256 internal mintedCards;

    // Contract Controllers
    address internal contractPacks;      // Points to CryptoCardPacks Contract
    address internal contractController; // Points to CryptoCardsController Contract

    // Mapping from token ID to card-data
    mapping(uint256 => Card) internal cardDataById;
    mapping(uint256 => TradeValue) internal cardTradeValueById;
    mapping(uint256 => uint256) internal cardSalePriceById;

    modifier onlyController() {
        require(msg.sender == contractController);
        _;
    }

    modifier onlyPacks() {
        require(msg.sender == contractPacks);
        _;
    }

    constructor() ERC721Token("Crypto-Cards - Cards", "CARDS") public {
    }

    function initialize(address _controller, address _packs) public onlyOwner {
        contractController = _controller;
        contractPacks = _packs;
    }

    function setContractPacks(address _packs) public onlyOwner {
        contractPacks = _packs;
    }

    function setContractController(address _controller) public onlyOwner {
        contractController = _controller;
    }

    function updateEndpoint(string _endpoint) public onlyOwner {
        endpoint = _endpoint;
    }

    function totalMintedCards() public view returns (uint256) {
        return mintedCards;
    }

    function cardHashById(uint256 _cardId) public view returns (string) {
        require(_cardId >= 0 && _cardId < mintedCards);
        return cardDataById[_cardId].hash;
    }

    function cardIssueById(uint256 _cardId) public view returns (uint16) {
        require(_cardId >= 0 && _cardId < mintedCards);
        return cardDataById[_cardId].issue;
    }

    function cardIndexById(uint256 _cardId) public view returns (uint8) {
        require(_cardId >= 0 && _cardId < mintedCards);
        return cardDataById[_cardId].index;
    }

    function cardGenById(uint256 _cardId) public view returns (uint8) {
        require(_cardId >= 0 && _cardId < mintedCards);
        return cardDataById[_cardId].gen;
    }

    function updateCardPrice(address _owner, uint256 _cardId, uint256 _cardPrice) public onlyController {
        require(_cardId >= 0 && _cardId < mintedCards);
        address cardOwner = tokenOwner[_cardId];
        require(cardOwner != address(0) && _owner == cardOwner);
        cardSalePriceById[_cardId] = _cardPrice;
    }

    function updateCardTradeValue(address _owner, uint256 _cardId, uint8 _cardValue, uint8 _cardGen) public onlyController {
        require(_cardId >= 0 && _cardId < mintedCards);
        address cardOwner = tokenOwner[_cardId];
        require(cardOwner != address(0) && _owner == cardOwner);
        cardTradeValueById[_cardId].index = _cardValue;
        cardTradeValueById[_cardId].gen = _cardGen;
    }

    function transferCardForBuyer(address _purchaser, address _owner, uint256 _cardId, uint256 _pricePaid) public onlyController returns (uint256) {
        require(_cardId >= 0 && _cardId < mintedCards);
        address cardOwner = tokenOwner[_cardId];
        require(cardOwner != address(0) && _owner == cardOwner && _purchaser != cardOwner);

        uint256 cardPrice = cardSalePriceById[_cardId];
        require(cardPrice > 0 && _pricePaid >= cardPrice);

        transferCard(cardOwner, _purchaser, _cardId);

        return cardPrice;
    }

    function tradeCardForCard(address _trader, address _tradee, uint256 _traderCardId, uint256 _tradeeCardId) public onlyController {
        require(_traderCardId >= 0 && _traderCardId < mintedCards && _tradeeCardId >= 0 && _tradeeCardId < mintedCards);
        address traderCardOwner = tokenOwner[_traderCardId];
        address tradeeCardOwner = tokenOwner[_tradeeCardId];
        require(traderCardOwner != address(0) && traderCardOwner == _trader);
        require(tradeeCardOwner != address(0) && tradeeCardOwner == _tradee);

        // Validate Trade
        require(cardTradeValueById[_tradeeCardId].index == cardDataById[_traderCardId].index);
        if (cardTradeValueById[_tradeeCardId].gen > 0) {
            require(cardTradeValueById[_tradeeCardId].gen == cardDataById[_traderCardId].gen);
        }

        // Trade Cards
        transferCard(traderCardOwner, tradeeCardOwner, _traderCardId);
        transferCard(tradeeCardOwner, traderCardOwner, _tradeeCardId);
    }

    /**
     * @dev Mint card
     * @param _to The address that will own the minted card
     * @param _cardData String representation of the metadata of the card to be minted
     */
    function mintCard(address _to, string _cardData) public onlyPacks returns (uint256) {
        uint cardId = mintedCards;
        _mint(_to, cardId);
        strings.slice memory cardDataSlice = _cardData.toSlice();
        _setTokenURI(cardId, endpoint.toSlice().concat(cardDataSlice));

        uint256 cardData = Helpers.parseInt(_cardData, 16);
        cardDataById[cardId].hash = _cardData;
        cardDataById[cardId].issue = uint16(Helpers.readBits(cardData, 0, 22));
        cardDataById[cardId].index = uint8(Helpers.readBits(cardData, 22, 8));
        cardDataById[cardId].gen = uint8(Helpers.readBits(cardData, 30, 2));

        mintedCards++;
        return cardId;
    }

    function transferCard(address _from, address _to, uint256 _cardId) internal {
        require(_from != address(0));
        require(_to != address(0));

        resetCardValue(_cardId);
        clearApproval(_from, _cardId);
        removeTokenFrom(_from, _cardId);
        addTokenTo(_to, _cardId);
    }

    function resetCardValue(uint256 _cardId) private {
        cardSalePriceById[_cardId] = 0;
        cardTradeValueById[_cardId].index = 0;
        cardTradeValueById[_cardId].gen = 0;
    }

    function _burn() internal pure {
        revert();
    }
}

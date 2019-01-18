/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2019 (c) Phat Cats, Inc.
 */

pragma solidity 0.4.24;

import "./strings.sol";
//import "github.com/Arachnid/solidity-stringutils/strings.sol";

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/math/SafeMath.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "openzeppelin-eth/contracts/token/ERC721/StandaloneERC721.sol";

import "./CryptoCardsLib.sol";
import "./CryptoCardPacks.sol";

/**
 * @title Crypto-Cards Card Token
 * ERC721-compliant token representing individual Cards
 */
contract CryptoCards is Initializable, Ownable {
    using SafeMath for uint256;
    using strings for *;

    StandaloneERC721 private erc721;
    CryptoCardsLib private cryptoCardsLib;
    CryptoCardPacks private cryptoCardPacks;

    // Info-URI Endpoint
    string private endpoint;

    // Contract Controller
    address public contractController; // Points to CryptoCardsController Contract

    // Mapping from token ID to sell-value
    mapping(uint256 => uint256) private cardSalePriceById;

    // Mapping from token ID to card-data
    mapping(uint256 => string) private cardHashByTokenId;
    mapping(uint256 => uint16) private cardIssueByTokenId;
    mapping(uint256 => uint8) private cardIndexByTokenId;
    mapping(uint256 => uint8) private cardGenByTokenId;

    // Mapping from token ID to trade-value
    mapping(uint256 => uint8) private cardTradeIndexByTokenId;
    mapping(uint256 => uint8) private cardTradeGenByTokenId;

    /**
     * @dev Throws if called by any account other than the controller contract.
     */
    modifier onlyController() {
        require(msg.sender == contractController);
        _;
    }

    /**
     * @dev Throws if called by any account other than the packs contract.
     */
    modifier onlyPacks() {
        require(msg.sender == address(cryptoCardPacks));
        _;
    }

    /**
     * @dev Initializes the Contract with the Token Symbol & Description
     */
    function initialize(address _owner) public initializer {
        Ownable.initialize(_owner);
        endpoint = "https://crypto-cards.io/card-info/";
    }

    /**
     * @dev Updates the internal address of the Controller Contract
     */
    function setContractController(address _controller) public onlyOwner {
        require(_controller != address(0));
        contractController = _controller;
    }

    function setPacksAddress(CryptoCardPacks _packs) public onlyOwner {
        require(_packs != address(0));
        cryptoCardPacks = _packs;
    }

    /**
     * @dev todo...
     */
    function setErcToken(StandaloneERC721 _token) public onlyOwner {
        require(_token != address(0));
        erc721 = _token;
    }

    function setLibAddress(CryptoCardsLib _lib) public onlyOwner {
        require(_lib != address(0));
        cryptoCardsLib = _lib;
    }

    /**
     * @dev Updates the URI end-point for the Token Metadata
     */
    function updateEndpoint(string _endpoint) public onlyOwner {
        endpoint = _endpoint;
    }

    /**
     * @dev Returns the total count of Minted Cards
     */
    function totalMintedCards() public view returns (uint256) {
        return erc721.totalSupply();
    }

    /**
     * @dev Returns the number of Cards for a specific Owner
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return erc721.balanceOf(_owner);
    }

    /**
     * @dev Returns the Signature Hash of the Card
     * Signature hash contains the hexadecimal representation of the Card Data (rank, gen, issue) as a string
     */
    function cardHashById(uint256 _cardId) public view returns (string) {
        require(_cardId >= 0 && _cardId < erc721.totalSupply());
        return cardHashByTokenId[_cardId];
    }

    /**
     * @dev Returns the Issue Number of the Card
     */
    function cardIssueById(uint256 _cardId) public view returns (uint16) {
        require(_cardId >= 0 && _cardId < erc721.totalSupply());
        return cardIssueByTokenId[_cardId];
    }

    /**
     * @dev Returns the Rank Number of the Card (0=Bitcoin, 1=Ethereum, etc..)
     */
    function cardIndexById(uint256 _cardId) public view returns (uint8) {
        require(_cardId >= 0 && _cardId < erc721.totalSupply());
        return cardIndexByTokenId[_cardId];
    }

    /**
     * @dev Returns the Generation of the Card
     */
    function cardGenById(uint256 _cardId) public view returns (uint8) {
        require(_cardId >= 0 && _cardId < erc721.totalSupply());
        return cardGenByTokenId[_cardId];
    }

    /**
     * @dev todo..
     */
    function updateCardPrice(address _owner, uint256 _cardId, uint256 _cardPrice) public onlyController {
        require(_cardId >= 0 && _cardId < erc721.totalSupply());
        address cardOwner = erc721.ownerOf(_cardId);
        require(cardOwner != address(0) && _owner == cardOwner);
        cardSalePriceById[_cardId] = _cardPrice;
    }

    /**
     * @dev todo..
     */
    function updateCardTradeValue(address _owner, uint256 _cardId, uint8 _cardValue, uint8 _cardGen) public onlyController {
        require(_cardId >= 0 && _cardId < erc721.totalSupply());
        address cardOwner = erc721.ownerOf(_cardId);
        require(cardOwner != address(0) && _owner == cardOwner);
        cardTradeIndexByTokenId[_cardId] = _cardValue;
        cardTradeGenByTokenId[_cardId] = _cardGen;
    }

    /**
     * @dev todo..
     */
    function transferCardForBuyer(address _receiver, address _owner, uint256 _cardId, uint256 _pricePaid) public onlyController returns (uint256) {
        require(_cardId >= 0 && _cardId < erc721.totalSupply());
        address cardOwner = erc721.ownerOf(_cardId);
        require(cardOwner != address(0) && _owner == cardOwner && _receiver != cardOwner);

        uint256 cardPrice = cardSalePriceById[_cardId];
        require(cardPrice > 0 && _pricePaid >= cardPrice);

        transferCard(cardOwner, _receiver, _cardId);

        return cardPrice;
    }

    /**
     * @dev todo..
     */
    function tradeCardForCard(address _owner, uint256 _ownerCardId, uint256 _tradeCardId) public onlyController returns (address) {
        require(_tradeCardId >= 0 && _tradeCardId < erc721.totalSupply() && _ownerCardId >= 0 && _ownerCardId < erc721.totalSupply());
        address ownerCardRealOwner = erc721.ownerOf(_ownerCardId);
        address tradeCardRealOwner = erc721.ownerOf(_tradeCardId);
        require(ownerCardRealOwner == _owner);
        require(tradeCardRealOwner != address(0));

        // Validate Trade
        require(cardTradeIndexByTokenId[_tradeCardId] == (cardIndexByTokenId[_ownerCardId] + 1));
        if (cardTradeGenByTokenId[_tradeCardId] > 0) {
            require(cardTradeGenByTokenId[_tradeCardId] == (cardGenByTokenId[_ownerCardId] + 1));
        }

        // Trade Cards
        transferCard(ownerCardRealOwner, tradeCardRealOwner, _ownerCardId); // initiator gives first
        transferCard(tradeCardRealOwner, ownerCardRealOwner, _tradeCardId);
        return tradeCardRealOwner;
    }

    /**
     * @dev Mint card
     * @param _to The address that will own the minted card
     * @param _cardData string String representation of the metadata of the card to be minted
     */
    function mintCard(address _to, string _cardData) public onlyPacks returns (uint256) {
        uint cardId = erc721.totalSupply();
        strings.slice memory cardDataSlice = _cardData.toSlice();
        erc721.mintWithTokenURI(_to, cardId, endpoint.toSlice().concat(cardDataSlice));

        uint256 cardData = cryptoCardsLib.bytesToUint(cryptoCardsLib.fromHex(_cardData));
        cardHashByTokenId[cardId] = _cardData;
        cardIssueByTokenId[cardId] = uint16(cryptoCardsLib.readBits(cardData, 0, 22));
        cardIndexByTokenId[cardId] = uint8(cryptoCardsLib.readBits(cardData, 22, 8));
        cardGenByTokenId[cardId] = uint8(cryptoCardsLib.readBits(cardData, 30, 2));
        return cardId;
    }

    /**
     * @dev todo..
     */
    function transferCard(address _from, address _to, uint256 _cardId) internal {
        require(_from != address(0));
        require(_to != address(0));

        resetCardValue(_cardId);
        erc721.safeTransferFrom(_from, _to, _cardId);
    }

    /**
     * @dev todo..
     */
    function resetCardValue(uint256 _cardId) private {
        cardSalePriceById[_cardId] = 0;
        cardTradeIndexByTokenId[_cardId] = 0;
        cardTradeGenByTokenId[_cardId] = 0;
    }
}

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
import "openzeppelin-eth/contracts/lifecycle/Pausable.sol";
import "openzeppelin-eth/contracts/utils/ReentrancyGuard.sol";

import "./CryptoCardsLib.sol";
import "./CryptoCardsGum.sol";
import "./CryptoCardsTreasury.sol";
import "./CryptoCardsOracle.sol";
import "./CryptoCardPacks.sol";
import "./CryptoCards.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsController is Initializable, Ownable, Pausable, ReentrancyGuard {
    event BuyNewPack        (address indexed _receiver, bytes16 _uuid, uint256 _pricePaid, address _referredBy, uint256 _promoCode);
    event ReceivedNewPack   (address indexed _receiver, bytes16 _uuid, uint256 _packId);
    event OpenedPack        (address indexed _receiver, bytes16 _uuid, uint256 _packId, uint256[8] _cards);
    event PackError         (address indexed _receiver, bytes16 _uuid, string _errorCode);

    event PackPriceSet      (address indexed _owner, bytes16 _uuid, uint256 _packId, uint256 _price);
    event CardPriceSet      (address indexed _owner, bytes16 _uuid, uint256 _cardId, uint256 _price);
    event CardTradeValueSet (address indexed _owner, bytes16 _uuid, uint256 _cardId, uint8[] _cardValues, uint8[] _cardGens);

    event PackSale          (address indexed _owner, address indexed _receiver, bytes16 _uuid, uint256 _packId, uint256 _price);
    event CardSale          (address indexed _owner, address indexed _receiver, bytes16 _uuid, uint256 _cardId, uint256 _price);
    event CardTrade         (address indexed _owner, address indexed _receiver, bytes16 _uuid, uint256 _ownerCardId, uint256 _tradeCardId);
    event CardBurn          (address indexed _owner, uint256[] _ownerCardIds);

    event TokenTransfer     (address indexed _owner, address indexed _receiver, uint256 _tokenId, string _symbol); // Off-Dapp Transfers (Manual, OpenSea, Etc..)

    CryptoCardsLib internal cryptoCardsLib;
    CryptoCardsGum internal cryptoCardsGum;
    CryptoCardsTreasury internal cryptoCardsTreasury;
    CryptoCardsOracle internal cryptoCardsOracle;
    CryptoCardPacks internal cryptoCardPacks;
    CryptoCards internal cryptoCards;

    // Token Addresses
    address internal cardsToken;
    address internal packsToken;

    mapping(address => uint256) internal purchasedPackCount;

    modifier onlyOracle() {
        require(msg.sender == address(cryptoCardsOracle));
        _;
    }

    modifier onlyTokens() {
        require(msg.sender == cardsToken || msg.sender == packsToken);
        _;
    }

    function initialize(address _owner) public initializer {
        Ownable.initialize(_owner);
        Pausable.initialize(_owner);
    }

    function setContractAddresses(
        CryptoCardsOracle _oracle,
        CryptoCards _cards,
        CryptoCardPacks _packs,
        CryptoCardsTreasury _treasury,
        CryptoCardsGum _gum,
        CryptoCardsLib _lib
    ) public onlyOwner {
        require(_oracle != address(0));
        require(_cards != address(0));
        require(_packs != address(0));
        require(_treasury != address(0));
        require(_gum != address(0));
        require(_lib != address(0));

        cryptoCardsOracle = _oracle;
        cryptoCards = _cards;
        cryptoCardPacks = _packs;
        cryptoCardsTreasury = _treasury;
        cryptoCardsGum = _gum;
        cryptoCardsLib = _lib;
    }

    function setCardsTokenAddress(address _token) public onlyOwner {
        require(_token != address(0));
        cardsToken = _token;
    }

    function setPacksTokenAddress(address _token) public onlyOwner {
        require(_token != address(0));
        packsToken = _token;
    }

    function getVersion() public pure returns (string) {
        return "v1.0.0";
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function transferToTreasury() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        cryptoCardsTreasury.deposit.value(balance)(balance, 0, address(0));
    }

    function getPromoCode(uint8 _index) public view returns (uint256) {
        return cryptoCardsLib.getPromoCode(_index);
    }

    function getReferralLevel(uint8 _index) public view returns (uint256) {
        return cryptoCardsLib.getReferralLevel(_index);
    }

    function getPurchasedPackCount(address _owner) public view returns (uint256) {
        return purchasedPackCount[_owner];
    }

    function getPriceAtGeneration(uint8 _generation) public view returns (uint256) {
        return cryptoCardsLib.getPriceAtGeneration(_generation);
    }

    function cardsOf(address _owner) public view returns (uint256) {
        return cryptoCards.balanceOf(_owner);
    }

    function packsOf(address _owner) public view returns (uint256) {
        return cryptoCardPacks.balanceOf(_owner);
    }

    function gumOf(address _owner) public view returns (uint256) {
        return cryptoCardsGum.balanceOf(_owner);
    }

    function unclaimedGumOf(address _owner) public view returns (uint256) {
        return cryptoCardPacks.unclaimedGumOf(_owner);
    }

    function paidReferralBalanceOf(address _account) public view returns (uint256) {
        return cryptoCardsTreasury.getPaidBalanceOfReferrer(_account);
    }

    function unpaidReferralBalanceOf(address _account) public view returns (uint256) {
        return cryptoCardsTreasury.getUnpaidBalanceOfReferrer(_account);
    }

    function paidBountyBalanceOf(address _account) public view returns (uint256) {
        return cryptoCardsTreasury.getPaidBalanceOfMember(_account);
    }

    function unpaidBountyBalanceOf(address _account) public view returns (uint256) {
        return cryptoCardsTreasury.getUnpaidBalanceOfMember(_account);
    }

    function availableBountyBalanceOf(address _account) public view returns (uint256) {
        return cryptoCardsTreasury.getAvailableBalanceOfMember(_account);
    }

    function bountyPayoutInterval() public view returns (uint256) {
        return cryptoCardsTreasury.getOutsourcedPayoutInterval();
    }

    function totalBalanceOfBountyPool() public view returns (uint256) {
        return cryptoCardsTreasury.getTotalBalanceOfPool();
    }

    function packIdOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        return cryptoCardPacks.tokenOfOwnerByIndex(_owner, _index);
    }

    function packDataById(uint256 _packId) public view returns (string) {
        return cryptoCardPacks.packDataById(_packId);
    }

    function cardHashById(uint256 _cardId) public view returns (string) {
        return cryptoCards.cardHashById(_cardId);
    }

    function isPackOpened(uint256 _packId) public view returns (bool) {
        return cryptoCardPacks.isPackOpened(_packId);
    }

    function isCardPrinted(uint256 _cardId) public view returns (bool) {
        return cryptoCards.isCardPrinted(_cardId);
    }

    function claimPackGum() public returns (uint256) {
        return cryptoCardPacks.claimPackGum(msg.sender);
    }

    function claimReferralRewards() public returns (uint256) {
        return cryptoCardsTreasury.withdrawForReferrer(msg.sender);
    }

    function claimBountyRewards() public returns (uint256) {
        return cryptoCardsTreasury.withdrawForMember(msg.sender);
    }

    function tokenizePack(uint256 _packId, bytes16 _uuid) public whenNotPaused {
        uint256[8] memory mintedCards = cryptoCardPacks.tokenizePack(msg.sender, _packId);
        emit OpenedPack(msg.sender, _uuid, _packId, mintedCards);
    }

    function clearPackPrice(uint256 _packId, bytes16 _uuid) public whenNotPaused {
        setPackPrice(msg.sender, _packId, 0, _uuid);
    }

    function updatePackPrice(uint256 _packId, uint256 _packPrice, bytes16 _uuid) public whenNotPaused {
        setPackPrice(msg.sender, _packId, _packPrice, _uuid);
    }

    function clearCardPrice(uint256 _cardId, bytes16 _uuid) public whenNotPaused {
        setCardPrice(msg.sender, _cardId, 0, _uuid);
    }

    function updateCardPrice(uint256 _cardId, uint256 _cardPrice, bytes16 _uuid) public whenNotPaused {
        setCardPrice(msg.sender, _cardId, _cardPrice, _uuid);
    }

    function clearCardTradeValue(uint256 _cardId, bytes16 _uuid) public whenNotPaused {
        setCardTradeValue(msg.sender, _cardId, new uint8[](0), new uint8[](0), _uuid);
    }

    function updateCardTradeValue(uint256 _cardId, uint8[] _cardValues, uint8[] _cardGens, bytes16 _uuid) public whenNotPaused {
        setCardTradeValue(msg.sender, _cardId, _cardValues, _cardGens, _uuid);
    }

    function buyPackFromOwner(address _owner, uint256 _packId, bytes16 _uuid) public nonReentrant whenNotPaused payable {
        require(_owner != address(0) && msg.sender != _owner);

        // Transfer Pack
        uint256 pricePaid = msg.value;
        uint256 packPrice = cryptoCardPacks.transferPackForBuyer(msg.sender, _owner, _packId, pricePaid);

        // Pay for Pack
        _owner.transfer(packPrice);

        // Emit Event to DApp
        emit PackSale(_owner, msg.sender, _uuid, _packId, packPrice);

        // Refund over-spend
        if (pricePaid > packPrice) {
            msg.sender.transfer(pricePaid - packPrice);
        }
    }

    function buyCardFromOwner(address _owner, uint256 _cardId, bytes16 _uuid) public nonReentrant whenNotPaused payable {
        require(_owner != address(0) && msg.sender != _owner);

        // Transfer Card
        uint256 pricePaid = msg.value;
        uint256 cardPrice = cryptoCards.transferCardForBuyer(msg.sender, _owner, _cardId, pricePaid);

        // Pay for Card
        _owner.transfer(cardPrice);

        // Emit Event to DApp
        emit CardSale(_owner, msg.sender, _uuid, _cardId, cardPrice);

        // Refund over-spend
        if (pricePaid > cardPrice) {
            msg.sender.transfer(pricePaid - cardPrice);
        }
    }

    function tradeCardForCard(address _owner, uint256 _ownerCardId, uint256 _tradeCardId, bytes16 _uuid) public nonReentrant whenNotPaused {
        require(_owner != address(0) && msg.sender == _owner);

        address trader = cryptoCards.tradeCardForCard(_owner, _ownerCardId, _tradeCardId);

        // Emit Event to DApp
        emit CardTrade(_owner, trader, _uuid, _ownerCardId, _tradeCardId);
    }

    function buyPackOfCards(address _referredBy, uint256 _promoCode, bytes16 _uuid) public nonReentrant whenNotPaused payable {
        uint256 currentGeneration = cryptoCardsOracle.getNextGeneration();
        require(msg.sender != address(0) && currentGeneration <= 3 && cryptoCardsOracle.isValidUuid(_uuid));

        bool hasReferral = false;
        if (_referredBy != address(0) && _referredBy != address(this)) {
            hasReferral = true;
        }

        uint256 pricePaid = msg.value;
        uint256 cost = cryptoCardsLib.getPricePerPack(currentGeneration-1, _promoCode, hasReferral);
        require(pricePaid >= cost);

        // Get Pack of Cards and Assign to Receiver
        uint256 oracleGasReserve = cryptoCardsOracle.getGasReserve();
        cryptoCardsOracle.getNewPack.value(oracleGasReserve)(msg.sender, oracleGasReserve, _uuid);

        // Distribute Payment for Pack
        uint256 netAmount = cost - oracleGasReserve;
        uint256 forReferrer = 0;
        if (hasReferral) {
            forReferrer = cryptoCardsLib.getAmountForReferrer(getPurchasedPackCount(_referredBy), cost);
        }

        // Deposit Funds to Treasury
        cryptoCardsTreasury.deposit.value(netAmount)(netAmount, forReferrer, _referredBy);

        // Emit Event to DApp
        emit BuyNewPack(msg.sender, _uuid, pricePaid, _referredBy, _promoCode);
        purchasedPackCount[msg.sender] = purchasedPackCount[msg.sender] + 1;

        // Refund over-spend
        if (pricePaid > cost) {
            msg.sender.transfer(pricePaid - cost);
        }
    }

    function freezePrintedCards_DoNotCallDirectly(uint256[] _cardIds) public {
        // Mark Cards as Printed
        cryptoCards.freezePrintedCards(msg.sender, _cardIds);
    }

    function receivedPackError(address _receiver, bytes16 _uuid, string _errorCode) public onlyOracle {
        emit PackError(_receiver, _uuid, _errorCode);  // API Error
    }

    function receivedNewPack(address _receiver, bytes16 _uuid, uint256 _packId) public onlyOracle {
        emit ReceivedNewPack(_receiver, _uuid, _packId);
    }

    function offDappTransfer(address _from, address _to, uint256 _tokenId, string _symbol) public onlyTokens {
        emit TokenTransfer(_from, _to, _tokenId, _symbol);
    }

    function setPackPrice(address _owner, uint256 _packId, uint256 _packPrice, bytes16 _uuid) internal {
        cryptoCardPacks.updatePackPrice(_owner, _packId, _packPrice);
        emit PackPriceSet(_owner, _uuid, _packId, _packPrice);
    }

    function setCardPrice(address _owner, uint256 _cardId, uint256 _cardPrice, bytes16 _uuid) internal {
        cryptoCards.updateCardPrice(_owner, _cardId, _cardPrice);
        emit CardPriceSet(_owner, _uuid, _cardId, _cardPrice);
    }

    function setCardTradeValue(address _owner, uint256 _cardId, uint8[] _cardValues, uint8[] _cardGens, bytes16 _uuid) internal {
        cryptoCards.updateCardTradeValue(_owner, _cardId, _cardValues, _cardGens);
        emit CardTradeValueSet(_owner, _uuid, _cardId, _cardValues, _cardGens);
    }
}

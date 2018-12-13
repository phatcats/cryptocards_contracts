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
import "./usingOraclize.sol";
import "zeppelin-solidity/contracts/ReentrancyGuard.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./pausable.sol";


contract CryptoCardsTreasury {
    function deposit(uint256 _amountDeposited, uint256 _amountForReferrer, address _referrer) public payable;
}


contract CryptoCards {
    function balanceOf(address _owner) public view returns (uint256);
    function cardHashById(uint256 _cardId) public view returns (string);
    function updateCardPrice(address _owner, uint256 _cardId, uint256 _cardPrice) public;
    function updateCardTradeValue(address _owner, uint256 _cardId, uint8 _cardValue, uint8 _cardGen) public;
    function transferCardForBuyer(address _purchaser, address _owner, uint256 _cardId, uint256 _pricePaid) public returns (uint256);
    function tradeCardForCard(address _trader, address _tradee, uint256 _traderCardId, uint256 _tradeeCardId) public;
}


contract CryptoCardPacks {
    function totalMintedPacks() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function packDataById(uint256 _packId) public view returns (string);
    function updatePackPrice(address _owner, uint256 _packId, uint256 _packPrice) public;
    function transferPackForBuyer(address _purchaser, address _owner, uint256 _packId, uint256 _pricePaid) public returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256);
    function mintPack(address _to, string _packData) public;
    function tokenizePack(address _opener, uint256 _packId) public returns (uint256[8]);
}


contract CryptoCardsOracle is Pausable, Helpers, usingOraclize {
    using SafeMath for uint256;
    using strings for *;

    event BuyNewPack        (address indexed _purchaser, bytes16 _uuid, uint256 _pricePaid, address _referredBy, uint256 _promoCode);
    event ReceivedNewPack   (address indexed _purchaser, bytes16 _uuid, uint256 _packId);
    event OpenedPack        (address indexed _purchaser, bytes16 _uuid, uint256 _packId, uint256[8] _cards);
    event PackError         (address indexed _purchaser, bytes16 _uuid, string _errorCode);

    event PackPriceSet      (address indexed _owner, bytes16 _uuid, uint256 _packId, uint256 _price);
    event CardPriceSet      (address indexed _owner, bytes16 _uuid, uint256 _cardId, uint256 _price);
    event CardTradeValueSet (address indexed _owner, bytes16 _uuid, uint256 _cardId, uint8 _cardValue, uint8 _cardGen);

    event PackSale          (address indexed _owner, address indexed _purchaser, bytes16 _uuid, uint256 _packId, uint256 _price);
    event CardSale          (address indexed _owner, address indexed _purchaser, bytes16 _uuid, uint256 _cardId, uint256 _price);
    event CardTrade         (address indexed _owner, address indexed _purchaser, bytes16 _uuid, uint256 _traderCardId, uint256 _tradeeCardId);

    CryptoCards internal CryptoCards_;
    CryptoCardPacks internal CryptoCardPacks_;
    CryptoCardsTreasury internal CryptoCardsTreasury_;

    uint256 internal oracleGasLimit = 350000;  // wei
    uint256 internal nextGeneration = 1; // Valid gens: 1, 2, or 3.   4 = Sold Out

    mapping(bytes32=>address) internal oracleIdToOwner;
    mapping(bytes32=>bytes16) internal oracleIdToUUID;
    mapping(bytes32=>bool) internal oracleIds;
    mapping(bytes16=>bool) internal uuids;

    string private apiEndpoint;

    constructor() public payable {
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Local Only
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        oraclize_setNetwork(networkID_testnet);
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        oraclize_setCustomGasPrice(10000000000); // 10 gwei
        pause();
    }

    function initialize(address _treasury, address _packsToken, address _cardsToken) public onlyOwner {
        CryptoCardsTreasury_ = CryptoCardsTreasury(_treasury);
        CryptoCardPacks_ = CryptoCardPacks(_packsToken);
        CryptoCards_ = CryptoCards(_cardsToken);
    }

    function updateApiEndpoint(string _endpoint) public onlyOwner {
        apiEndpoint = _endpoint;
    }

    function updateOracleGasPrice(uint _wei) public onlyOwner payable {
        oraclize_setCustomGasPrice(_wei);
    }

    function updateOracleGasLimit(uint _wei) public onlyOwner {
        oracleGasLimit = _wei;
    }

    function __callback(bytes32 _queryId, string _result) public {
        require(oracleIds[_queryId]);
        require(msg.sender == oraclize_cbAddress());
        require(bytes(_result).length > 0);

        address purchaser = oracleIdToOwner[_queryId];

        strings.slice memory s = _result.toSlice();
        // Code 0: Error
        // Code 1 - 3: Next Generation
        // Code 4: Sold-out
        uint256 responseCode = strToUint(s.split(".".toSlice()).toString());

        // Check for Error from API
        if (responseCode == 0) {
            emit PackError(purchaser, oracleIdToUUID[_queryId], _result);  // API Error
        } else {
            // Get Next Generation of Cards
            nextGeneration = responseCode;

            // Get Pack Data
            string memory packData = s.toString();
            uint256 packId = CryptoCardPacks_.totalMintedPacks();
            CryptoCardPacks_.mintPack(purchaser, packData);

            emit ReceivedNewPack(purchaser, oracleIdToUUID[_queryId], packId);
        }

        //        delete oracleIdToOwner[_queryId];
        //        delete oracleIdToUUID[_queryId];
        delete oracleIds[_queryId];
    }

    function getPackFromOracle(address _purchaser, bytes16 _uuid) internal returns (uint256) {
        uint256 oracleGasReserve = oraclize_getPrice("URL", oracleGasLimit);
        if (oracleGasReserve > address(this).balance) {
            emit PackError(_purchaser, _uuid, "100");  // Insufficient Funds for Oracle Error
        } else {
            bytes32 queryId = oraclize_query("URL", apiEndpoint, oracleGasLimit);
            oracleIdToOwner[queryId] = _purchaser;
            oracleIdToUUID[queryId] = _uuid;
            oracleIds[queryId] = true;
        }
        return oracleGasReserve;
    }
}


contract CryptoCardsController is CryptoCardsOracle, ReentrancyGuard {
    using SafeMath for uint256;
    using strings for *;

    uint256[3] private packPrices = [35 finney, 40 finney, 45 finney];
    uint256[3] private referralLevels = [8, 80, 160]; // packs: 3, 10, 20
    uint256[3] private promoCodes = [0, 0, 0];


    constructor() public payable {
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function transferToTreasury() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        CryptoCardsTreasury_.deposit.value(balance)(balance, 0, address(0));
    }

    function getPromoCode(uint8 _index) public view returns (uint256) {
        require(_index >= 0 && _index < 3);
        return promoCodes[_index];
    }

    function getPriceAtGeneration(uint8 _generation) public view returns (uint256) {
        require(_generation >= 0 && _generation < 3);
        return packPrices[_generation];
    }

    function updatePricePerPack(uint8 _generation, uint256 _price) public onlyOwner {
        require(_generation >= 0 && _generation < 3);
        require(_price > 1 finney);
        packPrices[_generation] = _price;
    }

    function updatePromoCode(uint8 _index, uint256 _code) public onlyOwner {
        require(_index >= 0 && _index < 3);
        promoCodes[_index] = _code;
    }

    function updateReferralLevels(uint8 _level, uint256 _amount) public onlyOwner {
        require(_level >= 0 && _level < 3 && _amount > 0);
        referralLevels[_level] = _amount;
    }

    function getTotalPacksOf(address _accountAddress) public view returns (uint256) {
        return CryptoCardPacks_.balanceOf(_accountAddress);
    }

    function getTotalCardsOf(address _accountAddress) public view returns (uint256) {
        return CryptoCards_.balanceOf(_accountAddress);
    }

    function packsOf(address _owner) public view returns (uint256) {
        return CryptoCardPacks_.balanceOf(_owner);
    }

    function packIdOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        return CryptoCardPacks_.tokenOfOwnerByIndex(_owner, _index);
    }

    function packDataById(uint256 _packId) public view returns (string) {
        return CryptoCardPacks_.packDataById(_packId);
    }

    function cardHashById(uint256 _cardId) public view returns (string) {
        return CryptoCards_.cardHashById(_cardId);
    }

    function tokenizePack(uint256 _packId, bytes16 _uuid) public whenNotPaused {
        uint256[8] memory mintedCards = CryptoCardPacks_.tokenizePack(msg.sender, _packId);
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
        setCardTradeValue(msg.sender, _cardId, 0, 0, _uuid);
    }

    function updateCardTradeValue(uint256 _cardId, uint8 _cardValue, uint8 _cardGen, bytes16 _uuid) public whenNotPaused {
        setCardTradeValue(msg.sender, _cardId, _cardValue, _cardGen, _uuid);
    }

    function buyPackFromOwner(address _owner, uint256 _packId, bytes16 _uuid) public nonReentrant whenNotPaused payable {
        require(_owner != address(0) && msg.sender != _owner);

        // Transfer Pack
        uint256 pricePaid = msg.value;
        uint256 packPrice = CryptoCardPacks_.transferPackForBuyer(msg.sender, _owner, _packId, pricePaid);

        // Pay for Pack
        _owner.transfer(packPrice);

        // Emit Event to DApp
        emit PackSale(_owner, msg.sender, _uuid, _packId, packPrice);

        // Refund over-spend
        if (pricePaid > packPrice) {
            msg.sender.transfer(pricePaid.sub(packPrice));
        }
    }

    function buyCardFromOwner(address _owner, uint256 _cardId, bytes16 _uuid) public nonReentrant whenNotPaused payable {
        require(_owner != address(0) && msg.sender != _owner);

        // Transfer Card
        uint256 pricePaid = msg.value;
        uint256 cardPrice = CryptoCards_.transferCardForBuyer(msg.sender, _owner, _cardId, pricePaid);

        // Pay for Card
        _owner.transfer(cardPrice);

        // Emit Event to DApp
        emit CardSale(_owner, msg.sender, _uuid, _cardId, cardPrice);

        // Refund over-spend
        if (pricePaid > cardPrice) {
            msg.sender.transfer(pricePaid.sub(cardPrice));
        }
    }

    function tradeCardForCard(address _owner, uint256 _ownerCardId, uint256 _tradeCardId, bytes16 _uuid) public nonReentrant whenNotPaused {
        require(_owner != address(0) && msg.sender != _owner);

        CryptoCards_.tradeCardForCard(msg.sender, _owner, _tradeCardId, _ownerCardId);

        // Emit Event to DApp
        emit CardTrade(_owner, msg.sender, _uuid, _tradeCardId, _ownerCardId);
    }

    function buyPackOfCards(address _referredBy, uint256 _promoCode, bytes16 _uuid) public nonReentrant whenNotPaused payable {
        require(msg.sender != address(0));
        require(nextGeneration <= 3);
        require(!uuids[_uuid]);
        uuids[_uuid] = true;

        bool hasReferral = false;
        if (_referredBy != address(0) && _referredBy != address(this)) {
            hasReferral = true;
        }

        uint256 pricePaid = msg.value;
        uint256 cost = getPricePerPack(_promoCode, hasReferral);
        require(pricePaid >= cost);

        // Get Pack of Cards and Assign to Purchaser
        uint256 oracleGasReserve = getPackFromOracle(msg.sender, _uuid);

        // Distribute Payment for Pack
        uint256 netAmount = cost.sub(oracleGasReserve);
        uint256 forReferrer = 0;
        if (hasReferral) {
            forReferrer = getAmountForReferrer(_referredBy, netAmount);
        }

        // Deposit Funds to Treasury
        CryptoCardsTreasury_.deposit.value(netAmount)(netAmount, forReferrer, _referredBy);

        // Emit Event to DApp
        emit BuyNewPack(msg.sender, _uuid, pricePaid, _referredBy, _promoCode);

        // Refund over-spend
        if (pricePaid > cost) {
            msg.sender.transfer(pricePaid.sub(cost));
        }
    }

    function getPricePerPack(uint256 _promoCode, bool _hasReferral) private view returns (uint256) {
        uint256 packPrice = packPrices[nextGeneration-1];

        // Promo Codes
        if (promoCodes[0] == _promoCode) {
            return packPrice.sub(packPrice.mul(5).div(100));    // 5% off
        }
        if (promoCodes[1] == _promoCode) {
            return packPrice.sub(packPrice.div(10));            // 10% off
        }
        if (promoCodes[2] == _promoCode) {
            return packPrice.sub(packPrice.mul(15).div(100));   // 15% off
        }

        // Referrals
        if (_hasReferral) {
            return packPrice.sub(packPrice.mul(5).div(100));    // 5% off
        }

        // Default (Full) Price
        return packPrice;
    }

    function getAmountForReferrer(address _referredBy, uint256 _cost) private view returns (uint256) {
        uint256 packCount = CryptoCardPacks_.balanceOf(_referredBy);
        uint256 cardCount = CryptoCards_.balanceOf(_referredBy);
        cardCount = packCount.mul(8).add(cardCount);

        if (cardCount >= referralLevels[2]) {
            return _cost.mul(15).div(100);    // 15%
        }
        if (cardCount >= referralLevels[1]) {
            return _cost.div(10);             // 10%
        }
        if (cardCount >= referralLevels[0]) {
            return _cost.div(20);             // 5%
        }
        return 0;
    }

    function setPackPrice(address _owner, uint256 _packId, uint256 _packPrice, bytes16 _uuid) private {
        CryptoCardPacks_.updatePackPrice(_owner, _packId, _packPrice);
        emit PackPriceSet(_owner, _uuid, _packId, _packPrice);
    }

    function setCardPrice(address _owner, uint256 _cardId, uint256 _cardPrice, bytes16 _uuid) private {
        CryptoCards_.updateCardPrice(_owner, _cardId, _cardPrice);
        emit CardPriceSet(_owner, _uuid, _cardId, _cardPrice);
    }

    function setCardTradeValue(address _owner, uint256 _cardId, uint8 _cardValue, uint8 _cardGen, bytes16 _uuid) private {
        CryptoCards_.updateCardTradeValue(_owner, _cardId, _cardValue, _cardGen);
        emit CardTradeValueSet(_owner, _uuid, _cardId, _cardValue, _cardGen);
    }
}

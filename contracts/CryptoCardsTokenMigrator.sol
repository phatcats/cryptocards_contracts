
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

import "./CryptoCardsPackToken.sol";
import "./CryptoCardsCardToken.sol";
import "./CryptoCardsGumToken.sol";

// Old Cards Controller (links to token)
contract CryptoCardsOld {
    function balanceOf(address owner) public view returns (uint256);
    function cardHashById(uint256 _cardId) public view returns (string memory);
    function cardIssueById(uint256 _cardId) public view returns (uint16);
    function cardIndexById(uint256 _cardId) public view returns (uint8);
    function cardGenById(uint256 _cardId) public view returns (uint8);
}

contract CryptoCardsCardTokenOld {
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256);
}

// Old Packs Controller (links to token)
contract CryptoCardPacksOld {
    function balanceOf(address owner) public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256);
    function packDataById(uint256 tokenId) public view returns (string memory);
    function unclaimedGumOf(address owner) public view returns (uint256);
}

/**
 * @title Crypto-Cards Token Migrator
 */
contract CryptoCardsTokenMigrator is Initializable, Ownable {
    // New Contracts
    CryptoCardsGumToken internal _gumToken;
    CryptoCardsPackToken internal _packsToken;
    CryptoCardsCardToken internal _cardsToken;

    // Old Contracts
    CryptoCardsGumToken internal _gumTokenOld;
    CryptoCardPacksOld internal _packsOld;
    CryptoCardsOld internal _cardsOld;
    CryptoCardsCardTokenOld internal _cardsTokenOld;

    // THIS CONTRACT IS INITIAL GUM HOLDER

    // [0] = Reserve                (Sent to Reserve-Escrow Account)
    // [1] = In-House               (Sent to In-House Account)
    // [2] = Bounty Rewards         (Sent to Bounty-Rewards Account)
    // [3] = Marketing Rewards      (Sent to Marketing Rewards Account)
    // [4] = Airdrop                (Sent to Airdrop-Escrow Account)
    // [5] = For Packs              (Sent to CryptoCardsGum Contract for distribution)
    address[6] internal _initialAccounts;
    uint256[6] internal _initialAmounts;

    bool internal _initialTokensDistributed;

    uint256 internal _migratedGum;

    mapping (address => bool) internal _isMigrated;

    event OwnerGumMigrated(address indexed owner, uint256 oldAmount, uint256 newAmount);

    //
    // Initialize
    //
    function initialize(address owner) public initializer {
        Ownable.initialize(owner);

        _initialAmounts = [
             700000,  // minus _migratedGum
             700000,
             200000,
             200000,
             200000,
            1000000
        ];
        //  3000000  Total Supply
    }

    //
    // GUM Tokens - Distribution
    //

    function setInitialAccounts(address[] memory accounts) public onlyOwner {
        require(!_initialTokensDistributed, "Tokens have already been distributed to initial accounts");
        require(accounts.length == 6, "Invalid accounts supplied; must be an array of length 6");

        for (uint256 i = 0; i < 6; ++i) {
            require(accounts[i] != address(0), "Invalid address supplied for reserve account");
            _initialAccounts[i] = accounts[i];
        }
    }

    function distributeInitialGum() public onlyOwner {
        require(!_initialTokensDistributed, "Tokens have already been distributed to initial accounts");
        require(_initialAmounts[0] - _migratedGum > 0, "Migrated GUM is more than Reserve GUM");

        _transferGum(_initialAccounts[0], _initialAmounts[0] - _migratedGum);
        for (uint i = 1; i < _initialAccounts.length; i++) {
            _transferGum(_initialAccounts[i], _initialAmounts[i]);
        }

        _initialTokensDistributed = true;
    }

    function distributeGum(address to, uint256 amount) public onlyOwner {
        _transferGum(to, amount);
    }

    //
    // GUM Tokens - Migration
    //

    function migrateTokenHolder(address tokenHolder) public onlyOwner returns (uint256, uint256) {
        return _migrate(tokenHolder);
    }

    //
    // Cards Token Functions for Assisting Migration
    //

    function cardsBalanceOf(address owner) public view returns (uint256) {
        return _cardsOld.balanceOf(owner);
    }
    function cardsTokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        return _cardsTokenOld.tokenOfOwnerByIndex(owner, index);
    }
    function cardHashById(uint256 cardId) public view returns (string memory) {
        return _cardsOld.cardHashById(cardId);
    }
    function cardIssueFromHash(uint256 cardData) public pure returns (uint16) {
        return uint16(_readBits(cardData, 0, 22));
    }
    function cardRankFromHash(uint256 cardData) public pure returns (uint8) {
        return uint8(_readBits(cardData, 22, 8));
    }
    function mintCard(address to, uint256 tokenId) public onlyOwner {
        _cardsToken.mintCard(to, tokenId);
    }

    //
    // Packs Token Functions for Assisting Migration
    //

    function packsBalanceOf(address owner) public view returns (uint256) {
        return _packsOld.balanceOf(owner);
    }
    function packsTokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        return _packsOld.tokenOfOwnerByIndex(owner, index);
    }
    function packHashById(uint256 tokenId) public view returns (string memory) {
        return _packsOld.packDataById(tokenId);
    }
    function mintNewPack(address owner, string memory packData) public onlyOwner returns (uint256) {
        return _packsToken.mintPack(owner, packData);
    }

    //
    // Only Owner
    //

    function setGumToken(CryptoCardsGumToken gum) public onlyOwner {
        require(address(gum) != address(0), "Invalid gum address supplied");
        _gumToken = gum;
    }

    function setOldGumToken(CryptoCardsGumToken gum) public onlyOwner {
        require(address(gum) != address(0), "Invalid gum address supplied");
        _gumTokenOld = gum;
    }

    function setPacksToken(CryptoCardsPackToken packsToken) public onlyOwner {
        require(address(packsToken) != address(0), "Invalid packsToken address supplied");
        _packsToken = packsToken;
    }

    function setOldPacks(CryptoCardPacksOld packs) public onlyOwner {
        require(address(packs) != address(0), "Invalid packs address supplied");
        _packsOld = packs;
    }

    function setCardsToken(CryptoCardsCardToken cardsToken) public onlyOwner {
        require(address(cardsToken) != address(0), "Invalid cardsToken address supplied");
        _cardsToken = cardsToken;
    }

    function setOldCardsToken(CryptoCardsCardTokenOld cardsToken) public onlyOwner {
        require(address(cardsToken) != address(0), "Invalid cardsToken address supplied");
        _cardsTokenOld = cardsToken;
    }

    function setOldCards(CryptoCardsOld cards) public onlyOwner {
        require(address(cards) != address(0), "Invalid cards address supplied");
        _cardsOld = cards;
    }

    //
    // Private
    //

    function _migrate(address tokenHolder) internal returns (uint256, uint256) {
        require(!_isMigrated[tokenHolder], "Token Holder has already been migrated");

        // 10 Old GUM exchanged for 1 New GUM   (10x reduction)
        //   Old GUM Supply: 3,000,000,000
        //   New GUM Supply:     3,000,000      (1000x reduction)
        //     Value of New Tokens increases by 100x
        uint256 oldAmount = (_gumTokenOld.balanceOf(tokenHolder) + _packsOld.unclaimedGumOf(tokenHolder)) / (1 ether);
        uint256 remainder = (oldAmount % 10);
        uint256 newAmount = (((oldAmount - remainder) / 10) + (remainder > 0 ? 1 : 0)) * (1 ether);
        _migratedGum = _migratedGum + newAmount;
        _transferGum(tokenHolder, newAmount);
        _isMigrated[tokenHolder] = true;
        emit OwnerGumMigrated(tokenHolder, oldAmount, newAmount);
        return (oldAmount, newAmount);
    }

    function _transferGum(address to, uint256 amount) internal {
        _gumToken.transfer(to, amount);
    }

    function _readBits(uint num, uint from, uint len) public pure returns (uint) {
        uint mask = ((1 << len) - 1) << from;
        return (num & mask) >> from;
    }
}

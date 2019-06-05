
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

import "./CryptoCardsGumToken.sol";

contract CryptoCardPacks {
    function unclaimedGumOf(address _owner) public view returns (uint256);
}

/**
 * @title Crypto-Cards Gum Distributor
 */
contract CryptoCardsGumDistributor is Initializable, Ownable {
    CryptoCardsGumToken internal _gumToken;
    CryptoCardsGumToken internal _gumTokenOld;
    CryptoCardPacks internal _packsOld;

    // THIS CONTRACT IS INITIAL GUM HOLDER

    // [0] = In-House               (Sent to In-House Account)
    // [3] = Reserve                (Sent to Reserve-Escrow Account)
    // [1] = Bounty Rewards         (Sent to Bounty-Rewards Account)
    // [2] = Marketing Rewards      (Sent to Marketing Rewards Account)
    // [4] = Airdrop                (Sent to Airdrop-Escrow Account)
    // [5] = For Packs              (Sent to CryptoCardsGum Contract for distribution)
    address[6] internal _initialAccounts;
    uint256[6] internal _initialAmounts;

    bool internal _initialTokensDistributed;

    // [0] = existing tokens distributed from Bounty Rewards
    // [1] = existing tokens distributed from Pack Gum
    uint256[2] internal _migrationGum;

    mapping (address => bool) internal _isMigrated;

    event OwnerGumMigrated(address indexed owner, uint256 amount);

    //
    // Initialize
    //
    function initialize(address owner) public initializer {
        Ownable.initialize(owner);

        _migrationGum = [
            123456,
            123456
        ];
        _initialAmounts = [
            1000000000,
            1500000000,
             150000000  - _migrationGum[0],
             150000000,
             150000000,
            1050000000 - _migrationGum[1]
        ];
        //  4000000000
    }

    function setGumToken(CryptoCardsGumToken gum) public onlyOwner {
        require(address(gum) != address(0), "Invalid gum address supplied");
        _gumToken = gum;
    }

    function setOldGumToken(CryptoCardsGumToken gum) public onlyOwner {
        require(address(gum) != address(0), "Invalid gum address supplied");
        _gumTokenOld = gum;
    }

    function setOldPacks(CryptoCardPacks packs) public onlyOwner {
        require(address(packs) != address(0), "Invalid packs address supplied");
        _packsOld = packs;
    }

    function migrateForOwner(address owner) public onlyOwner {
        _migrate(owner);
    }

    function migrateForOwners(address[] memory owners) public onlyOwner {
        for (uint256 i = 0; i < owners.length; i++) {
            _migrate(owners[i]);
        }
    }

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

        for (uint i = 0; i < _initialAccounts.length; i++) {
            _transferGum(_initialAccounts[i], _initialAmounts[i]);
        }

        _initialTokensDistributed = true;
    }

    function distributeGum(address to, uint256 amount) public onlyOwner {
        _transferGum(to, amount);
    }

    function _transferGum(address to, uint256 amount) internal {
        _gumToken.transfer(to, amount);
    }

    function _migrate(address owner) internal {
        require(!_isMigrated[owner], "Owner has already been migrated");
        uint256 amount = _gumTokenOld.balanceOf(owner) + _packsOld.unclaimedGumOf(owner);
        _transferGum(owner, amount);
        _isMigrated[owner] = true;
        emit OwnerGumMigrated(owner, amount);
    }
}

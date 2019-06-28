
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

    function migrateTokenHolder(address tokenHolder) public onlyOwner returns (uint256, uint256) {
        return _migrate(tokenHolder);
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

    function _transferGum(address to, uint256 amount) internal {
        _gumToken.transfer(to, amount);
    }

    function _migrate(address tokenHolder) internal returns (uint256, uint256) {
        require(!_isMigrated[tokenHolder], "Token Holder has already been migrated");

        // 10 Old GUM exchanged for 1 New GUM   (10x reduction)
        //   Old GUM Supply: 3,000,000,000
        //   New GUM Supply:     3,000,000      (1000x reduction)
        //     Value of New Tokens increases by 100x
        uint256 oldAmount = (_gumTokenOld.balanceOf(tokenHolder) + _packsOld.unclaimedGumOf(tokenHolder));
        uint256 newAmount = oldAmount / 10 + (oldAmount % 10 > 0 ? 1 : 0);
        _migratedGum = _migratedGum + newAmount;
        _transferGum(tokenHolder, newAmount);
        _isMigrated[tokenHolder] = true;
        emit OwnerGumMigrated(tokenHolder, oldAmount, newAmount);
        return (oldAmount, newAmount);
    }
}

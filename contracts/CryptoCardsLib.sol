/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2019 (c) Phat Cats, Inc.
 */

pragma solidity 0.5.2;

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "openzeppelin-eth/contracts/access/roles/SignerRole.sol";

//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsLib is Initializable, Ownable, SignerRole {
    uint256 private constant MAX_LEVELS = 3;
    uint256 private constant MAX_CODES = 3;

    uint256 internal _packPrice;

    uint256[MAX_LEVELS] internal _referralLevels;
    uint256[MAX_CODES] internal _promoCodes;
    uint256[MAX_CODES] internal _promoDiscounts;

    mapping(address => uint256) internal _purchasedPackCount;

    // Contract Reference Addresses
    address internal _controller;

    //
    // Modifiers
    //
    modifier onlyController() {
        require(msg.sender == _controller, "Action only allowed by Controller contract");
        _;
    }

    function initialize(address owner) public initializer {
        Ownable.initialize(owner);
        SignerRole.initialize(owner);

        _packPrice = 10 finney;
        _referralLevels = [1, 10, 20];
        _promoCodes = [123, 456, 789];
        _promoDiscounts = [5, 10, 15];
    }

    function getPurchasedPackCount(address owner) public view returns (uint256) {
        return _purchasedPackCount[owner];
    }

    function getPromoCode(uint8 index) public view returns (uint256) {
        require(index >= 0 && index < MAX_CODES, "Invalid index supplied");
        return _promoCodes[index];
    }

    function getPromoDiscount(uint8 index) public view returns (uint256) {
        require(index >= 0 && index < MAX_CODES, "Invalid index supplied");
        return _promoDiscounts[index];
    }

    function getReferralLevel(uint8 index) public view returns (uint256) {
        require(index >= 0 && index < MAX_LEVELS, "Invalid index supplied");
        return _referralLevels[index];
    }

    function getPrice() public view returns (uint256) {
        return _packPrice;
    }

    function getPricePerPack(uint256 promoCode, bool hasReferral) public view returns (uint256) {
        // Promo Codes
        for (uint256 i = 0; i < MAX_CODES; i++) {
            if (_promoCodes[i] == promoCode) {
                return _packPrice - (_packPrice * _promoDiscounts[i] / 100);
            }
        }

        // Referrals
        if (hasReferral) {
            return _packPrice - (_packPrice / 20);    // 5% off
        }

        // Default (Full) Price
        return _packPrice;
    }

    function getAmountForReferrer(address referrer, uint256 cost) public view returns (uint256) {
        if (_purchasedPackCount[referrer] >= _referralLevels[2]) {
            return cost * 15 / 100;     // 15%
        }
        if (_purchasedPackCount[referrer] >= _referralLevels[1]) {
            return cost / 10;           // 10%
        }
        if (_purchasedPackCount[referrer] >= _referralLevels[0]) {
            return cost / 20;           // 5%
        }
        return 0;
    }

    // @dev from https://ethereum.stackexchange.com/questions/10932/how-to-convert-string-to-int
    function strToUint(string memory s) public pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        uint len = b.length;
        for (uint i = 0; i < len; i++) {
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint8(b[i]) - 48);
            }
        }
        return result;
    }

    // @dev from https://ethereum.stackexchange.com/questions/64998/converting-from-bytes-in-0-5-x
    function bytesToUint(bytes memory b) public pure returns (uint256) {
        uint256 number;
        for (uint i = 0; i < b.length; i++) {
            number = number + uint256(uint8(b[i])) * (2**(8 * (b.length-(i+1))));
        }
        return number;
    }

    // Convert an hexadecimal character to their value
    function fromHexChar(uint8 c) public pure returns (uint8) {
        if (byte(c) >= byte('0') && byte(c) <= byte('9')) {
            return c - uint8(byte('0'));
        }
        if (byte(c) >= byte('a') && byte(c) <= byte('f')) {
            return 10 + c - uint8(byte('a'));
        }
        if (byte(c) >= byte('A') && byte(c) <= byte('F')) {
            return 10 + c - uint8(byte('A'));
        }
        return 0;
    }

    // Convert an hexadecimal string to raw bytes
    function fromHex(string memory s) public pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = byte(fromHexChar(uint8(ss[2*i])) * 16 + fromHexChar(uint8(ss[2*i+1])));
        }
        return r;
    }

    function _readBits(uint num, uint from, uint len) private pure returns (uint) {
        uint mask = ((1 << len) - 1) << from;
        return (num & mask) >> from;
    }

    //
    // Only Controller
    //

    function incrementPurchasedPackCount(address owner, uint256 amount) public onlyController returns (uint256) {
        _purchasedPackCount[owner] = _purchasedPackCount[owner] + amount;
        return _purchasedPackCount[owner];
    }

    //
    // Only Signer
    //

    function updatePricePerPack(uint256 price) public onlySigner {
        require(price > 5 finney, "price must be higher than 0.005 ETH");
        _packPrice = price;
    }

    function updatePromoCode(uint8 index, uint256 code) public onlySigner {
        require(index >= 0 && index < MAX_CODES, "Invalid index supplied");
        _promoCodes[index] = code;
    }

    //
    // Only Owner
    //

    function setContractController(address controller) public onlyOwner {
        require(controller != address(0), "Invalid address supplied");
        _controller = controller;
    }

    function updatePromoDiscount(uint8 index, uint256 discount) public onlyOwner {
        require(index >= 0 && index < MAX_CODES, "Invalid index supplied");
        _promoDiscounts[index] = discount;
    }

    function updateReferralLevels(uint8 level, uint256 amount) public onlyOwner {
        require(level >= 0 && level < MAX_LEVELS, "Invalid level supplied");
        require(amount > 0, "amount must be greater than zero");
        _referralLevels[level] = amount;
    }
}

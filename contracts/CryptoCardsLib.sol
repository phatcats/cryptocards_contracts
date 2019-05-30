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

pragma solidity 0.4.24;

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsLib is Initializable, Ownable {
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

        _packPrice = 15 finney;
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
    function strToUint(string s) public pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        uint len = b.length;
        for (uint i = 0; i < len; i++) {
            if (b[i] >= 48 && b[i] <= 57) {
                result = result * 10 + (uint(b[i]) - 48);
            }
        }
        return result;
    }

    // @dev from https://ethereum.stackexchange.com/questions/6591/conversion-of-uint-to-string
    function uintToHexStr(uint i) public pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            uint curr = (i & mask);
            bstr[k--] = curr > 9 ? byte(87 + curr) : byte(48 + curr); // 87 = 97 - 10
            i = i >> 4;
        }
        return string(bstr);
    }

    // @dev from https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function uint2str(uint _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    // @dev from https://ethereum.stackexchange.com/questions/39989/solidity-convert-hex-string-to-bytes
    function fromHexChar(uint c) public pure returns (uint) {
        if (byte(c) >= byte('0') && byte(c) <= byte('9')) {
            return c - uint(byte('0'));
        }
        if (byte(c) >= byte('a') && byte(c) <= byte('f')) {
            return 10 + c - uint(byte('a'));
        }
        if (byte(c) >= byte('A') && byte(c) <= byte('F')) {
            return 10 + c - uint(byte('A'));
        }
    }

    // @dev from https://ethereum.stackexchange.com/questions/39989/solidity-convert-hex-string-to-bytes
    function fromHex(string s) public pure returns (bytes) {
        bytes memory ss = bytes(s);
        uint len = ss.length;
        require(len%2 == 0, 'fromHex: length must be even');
        bytes memory r = new bytes(len/2);
        for (uint i=0; i<len/2; ++i) {
            r[i] = byte(fromHexChar(uint(ss[2*i])) * 16 + fromHexChar(uint(ss[2*i+1])));
        }
        return r;
    }

    // @dev from https://ethereum.stackexchange.com/questions/51229/how-to-convert-bytes-to-uint-in-solidity
    function bytesToUint(bytes b) public pure returns (uint256) {
        uint256 number;
        uint len = b.length;
        for(uint i=0;i<len;i++){
            number = number + uint(b[i])*(2**(8*(len-(i+1))));
        }
        return number;
    }

//    function _getBitPosition(uint32 val) private pure returns (uint) {
//        for (uint i = 0; i < 32; i++) {
//            if ((val & 1) == 1) {
//                return i;
//            }
//            val = val >>= 1;
//        }
//    }
//
//    function _traitByIndex(uint256 index) private pure returns (uint256) {
//        return uint256(1 << index);
//    }

    function _readBits(uint num, uint from, uint len) private pure returns (uint) {
        uint mask = ((1 << len) - 1) << from;
        return (num & mask) >> from;
    }

    //
    // Only Controller
    //

    function incrementPurchasedPackCount(address owner, uint256 amount) public onlyController returns (uint256) {
        _purchasedPackCount[owner] = _purchasedPackCount[owner] + amount;
    }

    //
    // Only Owner
    //

    function setContractController(address controller) public onlyOwner {
        require(controller != address(0), "Invalid address supplied");
        _controller = controller;
    }

    function updatePricePerPack(uint256 price) public onlyOwner {
        require(price > 5 finney, "price must be higher than 0.005 ETH");
        _packPrice = price;
    }

    function updatePromoCode(uint8 index, uint256 code) public onlyOwner {
        require(index >= 0 && index < MAX_CODES, "Invalid index supplied");
        _promoCodes[index] = code;
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

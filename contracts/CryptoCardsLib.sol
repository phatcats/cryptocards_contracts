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


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsLib is Initializable, Ownable {
    uint256[3] internal packPrices;
    uint256[3] internal referralLevels;
    uint256[3] internal promoCodes;


    function initialize(address _owner) public initializer {
        Ownable.initialize(_owner);

        packPrices = [15 finney, 17 finney, 20 finney];
        referralLevels = [8, 60, 180]; // packs: 1, 5, 15
        promoCodes = [5, 10, 15];
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

    function getPromoCode(uint8 _index) public view returns (uint256) {
        require(_index >= 0 && _index < 3);
        return promoCodes[_index];
    }

    function getPriceAtGeneration(uint8 _generation) public view returns (uint256) {
        require(_generation >= 0 && _generation < 3);
        return packPrices[_generation];
    }

    function getPricePerPack(uint256 _generation, uint256 _promoCode, bool _hasReferral) public view returns (uint256) {
        uint256 packPrice = packPrices[_generation];

        // Promo Codes
        if (promoCodes[0] == _promoCode) {
            return packPrice - (packPrice * 5 / 100);    // 5% off
        }
        if (promoCodes[1] == _promoCode) {
            return packPrice - (packPrice / 10);         // 10% off
        }
        if (promoCodes[2] == _promoCode) {
            return packPrice - (packPrice * 15 / 100);   // 15% off
        }

        // Referrals
        if (_hasReferral) {
            return packPrice - (packPrice * 5 / 100);    // 5% off
        }

        // Default (Full) Price
        return packPrice;
    }

    function getAmountForReferrer(uint256 _cardCount, uint256 _cost) public view returns (uint256) {
        if (_cardCount >= referralLevels[2]) {
            return _cost * 15 / 100;     // 15%
        }
        if (_cardCount >= referralLevels[1]) {
            return _cost / 10;           // 10%
        }
        if (_cardCount >= referralLevels[0]) {
            return _cost / 20;           // 5%
        }
        return 0;
    }

    function readBits(uint num, uint from, uint len) public pure returns (uint) {
        uint mask = ((1 << len) - 1) << from;
        return (num & mask) >> from;
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
}

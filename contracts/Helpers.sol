//  Copyright 2018 (c) Alabor, Inc.

pragma solidity ^0.4.24;

contract Helpers {
    function readBits(uint num, uint from, uint len) internal pure returns (uint) {
        uint mask = ((1 << len) - 1) << from;
        return (num & mask) >> from;
    }

    /**
     * @dev from https://ethereum.stackexchange.com/questions/10932/how-to-convert-string-to-int
     */
    function strToUint(string s) internal pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
            if (b[i] >= 48 && b[i] <= 57) {
                result = result * 10 + (uint(b[i]) - 48);
            }
        }
        return result;
    }

    /**
     * @dev from Oraclize https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
     */
    function uintToStr(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev from Oraclize https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
     */
    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                    if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

    /**
     * @dev from https://ethereum.stackexchange.com/questions/6591/conversion-of-uint-to-string
     */
    function uintToHexStr(uint i) internal pure returns (string) {
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
}

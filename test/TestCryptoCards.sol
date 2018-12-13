pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/CryptoCards.sol";


contract TestCryptoCards {
//    uint256 x;
//
//    constructor() public {
//
//    }
//    function beforeEach() public {
//        x = 0;
//    }

    function testInitialCount() public {
        CryptoCards cc = CryptoCards(DeployedAddresses.CryptoCards());

        uint expected = 0;
        Assert.equal(cc.totalMintedCards(), expected, "Total Minted Cards should be 0 initially");
    }
}

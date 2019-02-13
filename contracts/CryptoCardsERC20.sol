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


contract CryptoCardsERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
}

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


contract CryptoCardsGumToken {
    // ERC20
    function transfer(address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);

    // CryptoCardsGumToken
//    function transferFor(address from, address to, uint256 value) public;
//    function fastTransferFor(address to, uint256 value) public;
}

/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2019 (c) Phat Cats, Inc.
 */

pragma solidity 0.5.2;


contract CryptoCardsPackToken {
    // ERC721
    function balanceOf(address owner) public view returns (uint256);
    function ownerOf(uint256 tokenId) public view returns (address);
    function totalSupply() public view returns (uint256);

    // CryptoCardsPackToken
    function packDataById(uint256 tokenId) public view returns (string memory);
    function totalMintedPacks() public view returns (uint256);
    function mintPack(address to, string memory packData) public returns (uint256);
    function burnPack(address from, uint256 tokenId) public;
    function tokenTransfer(address from, address to, uint256 tokenId) public;
}

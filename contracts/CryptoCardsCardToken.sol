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


contract CryptoCardsCardToken {
    // ERC721
    function balanceOf(address owner) public view returns (uint256);
    function ownerOf(uint256 tokenId) public view returns (address);
    function totalSupply() public view returns (uint256);
//    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256);

    // ERC721-Batched
//    function safeBatchTransferFrom(address from, address to, uint256[] memory tokenIds) public;
//    function safeBatchTransferFrom(address from, address to, uint256[] memory tokenIds, bytes memory _data) public;
//    function batchTransferFrom(address from, address to, uint256[] memory tokenIds) public;

    // CryptoCardsCardToken
    function getTypeIndicators(uint256 tokenId) public pure returns (uint, uint, uint);
    function getTotalIssued(uint256 tokenId) public view returns (uint);
    function isTokenPrinted(uint256 tokenId) public view returns (bool);
    function canCombine(uint256 tokenA, uint256 tokenB) public view returns (bool);
    function getEarnedGum(address owner) public view returns (uint256);
    function claimEarnedGum(address owner, uint256 amountClaimed) public returns (uint256);
    function tokenTransfer(address from, address to, uint256 tokenId) public;

    function mintCardsFromPack(address to, uint256[] memory tokenIds) public;
    function mintCard(address to, uint256 tokenId) public;
    function printFor(address owner, uint256 tokenId) public;
    function combineFor(address owner, uint256 tokenA, uint256 tokenB) public returns (uint256);
    function meltFor(address owner, uint256 tokenId) public;

}

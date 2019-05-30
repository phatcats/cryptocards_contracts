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


contract CryptoCardsERC721 {
    function balanceOf(address owner) public view returns (uint256);
    function ownerOf(uint256 tokenId) public view returns (address);
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256);
    function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) public returns (bool);
    function tokenTransfer(address _from, address _to, uint256 _tokenId) public;
    function isTokenFrozen(uint256 _tokenId) public view returns (bool);
    function freezeToken(uint256 _tokenId) public;
}

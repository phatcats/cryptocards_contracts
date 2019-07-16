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

import "./strings.sol";

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";

import "./CryptoCardsPackToken.sol";
import "./CryptoCardsCardToken.sol";
import "./CryptoCardsLib.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsPacks is Initializable, Ownable {
    using strings for *;

    //
    // Storage
    //
    CryptoCardsPackToken internal _packToken;
    CryptoCardsCardToken internal _cardToken;
    CryptoCardsLib internal _lib;

    // Contract Reference Addresses
    address internal _controller;
    address internal _oracle;

    // Mapping from token ID to pack-data
    mapping(uint256 => uint256) internal _packSalePriceById;

    //
    // Events
    //
    event OpenedPack  (address indexed receiver, bytes16 uuid, uint256 packId, uint256[] cards);
    event PackPriceSet(address indexed owner, bytes16 uuid, uint256 packId, uint256 price);
    event PackSale    (address indexed owner, address indexed receiver, bytes16 uuid, uint256 packId, uint256 price);

    //
    // Modifiers
    //
    modifier onlyController() {
        require(msg.sender == _controller, "Action only allowed by Controller contract");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == _oracle, "Action only allowed by Oracle contract");
        _;
    }

    //
    // Initialize
    //
    function initialize(address owner) public initializer {
        Ownable.initialize(owner);
    }

    //
    // Public
    //

    function totalMintedPacks() public view returns (uint256) {
        return _packToken.totalSupply();
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _packToken.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _packToken.ownerOf(tokenId);
    }

    function packDataById(uint256 tokenId) public view returns (string memory) {
        return _packToken.packDataById(tokenId);
    }

//    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
//        return _packToken.tokenOfOwnerByIndex(owner, index);
//    }

    //
    // Only Owner
    //

    function setContractController(address controller) public onlyOwner {
        require(controller != address(0), "Invalid address supplied");
        _controller = controller;
    }

    function setOracleAddress(address oracle) public onlyOwner {
        require(oracle != address(0), "Invalid address supplied");
        _oracle = oracle;
    }

    function setCryptoCardsPackToken(CryptoCardsPackToken token) public onlyOwner {
        require(address(token) != address(0), "Invalid address supplied");
        _packToken = token;
    }

    function setCryptoCardsCardToken(CryptoCardsCardToken token) public onlyOwner {
        require(address(token) != address(0), "Invalid address supplied");
        _cardToken = token;
    }

    function setLibAddress(CryptoCardsLib lib) public onlyOwner {
        require(address(lib) != address(0), "Invalid address supplied");
        _lib = lib;
    }

    //
    // Only Controller Contract
    //

    function updatePackPrice(address owner, uint256 packId, uint256 packPrice, bytes16 uuid) public onlyController {
        address packOwner = _packToken.ownerOf(packId); // will revert if owner == address(0)
        require(owner == packOwner, "Invalid owner supplied or owner is not pack-owner");
        _packSalePriceById[packId] = packPrice;
        emit PackPriceSet(owner, uuid, packId, packPrice);
    }

    function transferPackForBuyer(address receiver, address owner, uint256 packId, uint256 pricePaid, bytes16 uuid) public onlyController returns (uint256) {
        address packOwner = _packToken.ownerOf(packId); // will revert if owner == address(0)
        require(owner == packOwner, "Invalid owner supplied or owner is not pack-owner");
        require(receiver != packOwner, "Cannot transfer pack to self");

        uint256 packPrice = _packSalePriceById[packId];
        require(packPrice > 0, "Pack is not for sale");
        require(pricePaid >= packPrice, "Pack price is greater than the price paid");

        _transferPack(packOwner, receiver, packId);

        emit PackSale(owner, receiver, uuid, packId, packPrice);

        return packPrice;
    }

    function openPack(address opener, uint256 packId, bytes16 uuid) public onlyController {
        address owner = _packToken.ownerOf(packId); // will revert if owner == address(0)
        require(opener == owner, "opener must be owner of pack");

        uint256[] memory mintedCards = new uint256[](8);
        strings.slice memory s = _packToken.packDataById(packId).toSlice();
        strings.slice memory d = ".".toSlice();
        s.split(d); // Skip response code
        for (uint i = 0; i < 8; i++) {
            mintedCards[i] = _lib.bytesToUint(_lib.fromHex(s.split(d).toString()));
        }
        _cardToken.mintCardsFromPack(owner, mintedCards);

        // Burn Pack Token
        _packToken.burnPack(opener, packId);

        emit OpenedPack(opener, uuid, packId, mintedCards);
    }

    //
    // Only Oracle Contract
    //

    function mintPack(address to, string memory packData) public onlyOracle returns (uint256) {
        return _packToken.mintPack(to, packData);
    }

    //
    // Private
    //

    function _transferPack(address from, address to, uint256 packId) internal {
        require(from != address(0), "Invalid from address supplied");
        require(to != address(0), "Invalid to address supplied");

        _resetPackValue(packId);
        _packToken.tokenTransfer(from, to, packId);
    }

    function _resetPackValue(uint256 packId) internal {
        _packSalePriceById[packId] = 0;
    }
}

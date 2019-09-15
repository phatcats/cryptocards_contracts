/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2019 (c) Phat Cats, Inc.
 */

pragma solidity 0.5.2;

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";

import "./CryptoCardsGumToken.sol";

//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsGum is Initializable, Ownable {
    uint256 private constant MAX_FLAVORS = 5;

    //
    // Storage
    //
    CryptoCardsGumToken[MAX_FLAVORS] internal _gumToken;

    bytes32[MAX_FLAVORS] internal _flavorName;
    uint256[MAX_FLAVORS] internal _gumPerPack;

    uint internal _flavorsAvailable;
    uint internal _earnedGumFlavor;

    address internal _cryptoCardsPacks;
    address internal _cryptoCardsCards;

    //
    // Modifiers
    //
    modifier onlyPacks() {
        require(msg.sender == _cryptoCardsPacks, "Action only allowed by Packs contract");
        _;
    }

    modifier onlyCards() {
        require(msg.sender == _cryptoCardsCards, "Action only allowed by Packs contract");
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

    function availableFlavors() public view returns (uint) {
        return _flavorsAvailable;
    }

    function gumFlavorAvailable(uint flavor) public view returns (bool) {
        if (flavor < 0 || flavor > MAX_FLAVORS) { return false; }
        return address(_gumToken[flavor]) != address(0x0);
    }

    function gumFlavorName(uint flavor) public view returns (bytes32) {
        if (!gumFlavorAvailable(flavor)) { return ""; }
        return _flavorName[flavor];
    }

    function gumFlavorAddress(uint flavor) public view returns (address) {
        if (!gumFlavorAvailable(flavor)) { return address(0x0); }
        return address(_gumToken[flavor]);
    }

    function gumPerPack(uint flavor) public view returns (uint256) {
        if (!gumFlavorAvailable(flavor)) { return 0; }
        return _gumPerPack[flavor];
    }

    function balanceOf(address owner, uint flavor) public view returns (uint256) {
        if (!gumFlavorAvailable(flavor)) { return 0; }
        return _gumToken[flavor].balanceOf(owner);
    }

    function packGumAvailable(uint flavor) public view returns (uint256) {
        return balanceOf(address(this), flavor);
    }

    //
    // Only Owner
    //

    function setPacksAddress(address packs) public onlyOwner {
        require(address(packs) != address(0x0), "Invalid address supplied");
        _cryptoCardsPacks = packs;
    }

    function setCardsAddress(address cards) public onlyOwner {
        require(address(cards) != address(0x0), "Invalid address supplied");
        _cryptoCardsCards = cards;
    }

    function setGumToken(CryptoCardsGumToken token, uint flavor, bytes32 flavorName) public onlyOwner {
        require(address(token) != address(0x0), "Invalid address supplied");
        require(flavor == _flavorsAvailable, "Invalid flavor supplied");

        _gumToken[flavor] = token;
        _flavorName[flavor] = flavorName;
        _flavorsAvailable = flavor + 1;
    }

    function setGumPerPack(uint flavor, uint256 amount) public onlyOwner {
        require(gumFlavorAvailable(flavor), "Flavor not available");
        _gumPerPack[flavor] = amount;
    }

    function setEarnedGumFlavor(uint flavor) public onlyOwner {
        require(gumFlavorAvailable(flavor), "Flavor not available");
        _earnedGumFlavor = flavor;
    }

    //
    // Only Cards Contract
    //

    function transferCardGum(address to, uint gumAmount) public onlyCards returns (uint256) {
        require(to != address(0x0), "Invalid address supplied");

        uint256 available = packGumAvailable(_earnedGumFlavor);
        if (gumAmount > available) {
            gumAmount = available;
        }

        // Transfer Gum Tokens
        _gumToken[_earnedGumFlavor].transfer(to, gumAmount);
        return gumAmount;
    }

    //
    // Only Packs Contract
    //

    function transferPackGum(address to, uint packCount) public onlyPacks returns (uint256) {
        require(to != address(0x0), "Invalid address supplied");

        uint256 gumAmount = _gumPerPack[_earnedGumFlavor] * packCount;
        uint256 available = packGumAvailable(_earnedGumFlavor);
        if (gumAmount > available) {
            gumAmount = available;
        }

        // Transfer Gum Tokens
        _gumToken[_earnedGumFlavor].transfer(to, gumAmount);
        return gumAmount;
    }
}

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

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";

import "./CryptoCardsGumToken.sol";
import "./CryptoCardsCardToken.sol";

//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsGum is Initializable, Ownable {
    uint256 private constant MAX_FLAVORS = 5;

    //
    // Storage
    //
    CryptoCardsCardToken internal _cardToken;
    CryptoCardsGumToken[MAX_FLAVORS] internal _gumToken;
    bytes32[MAX_FLAVORS] internal _flavorName;
    uint256[MAX_FLAVORS] internal _gumPerPack;
    uint internal _flavorsAvailable;
    uint internal _earnedGumFlavor;

    address internal _cryptoCardsController;
    address internal _cryptoCardsOracle;

    //
    // Modifiers
    //
    modifier onlyController() {
        require(msg.sender == _cryptoCardsController, "Action only allowed by Controller contract");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == _cryptoCardsOracle, "Action only allowed by Oracle contract");
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

    function setContractController(address controller) public onlyOwner {
        require(controller != address(0x0), "Invalid address supplied");
        _cryptoCardsController = controller;
    }

    function setOracleAddress(address oracle) public onlyOwner {
        require(oracle != address(0x0), "Invalid address supplied");
        _cryptoCardsOracle = oracle;
    }

    function setCardToken(CryptoCardsCardToken token) public onlyOwner {
        require(address(token) != address(0x0), "Invalid address supplied");
        _cardToken = token;
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
    // Only Controller Contract
    //

    function claimEarnedGum(address to) public onlyController returns (uint256) {
        require(to != address(0x0), "Invalid address supplied");

        uint256 earnedGum = _cardToken.getEarnedGum(to);
        uint256 available = packGumAvailable(_earnedGumFlavor);
        if (earnedGum > available) {
            earnedGum = available;
        }

        // Transfer Gum Tokens
        _cardToken.claimEarnedGum(to, earnedGum);
        _gumToken[_earnedGumFlavor].transfer(to, earnedGum);
        return earnedGum;
    }

    //
    // Only Oracle Contract
    //

    function transferPackGum(address to, uint packCount) public onlyOracle {
        for (uint i = 0; i < _flavorsAvailable; i++) {
            uint256 packGum = _gumPerPack[i] * packCount;
            uint256 available = packGumAvailable(i);
            if (packGum > available) {
                packGum = available;
            }
            _gumToken[i].transfer(to, packGum);
        }
    }
}

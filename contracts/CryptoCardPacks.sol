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

import "./strings.sol";

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";

import "./CryptoCardsERC721.sol";
import "./CryptoCardsLib.sol";
import "./CryptoCardsGum.sol";
import "./CryptoCards.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardPacks is Initializable, Ownable {
    using strings for *;

    CryptoCardsERC721 internal token;
    CryptoCards internal cards;
    CryptoCardsLib internal lib;
    CryptoCardsGum internal gum;

    uint256[3] internal packGumPerGeneration;

    // Info-URI Endpoint
    string internal endpoint;

    // Contract Reference Addresses
    address internal cryptoCardsController;
    address internal cryptoCardsOracle;

    // Mapping from token ID to pack-data
    mapping(uint256 => string) internal packsDataById;
    mapping(uint256 => uint256) internal packSalePriceById;
    mapping(address => uint256) internal packGumByOwner;  // Unclaimed

    modifier onlyController() {
        require(msg.sender == cryptoCardsController, "Action only allowed by Controller contract");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == cryptoCardsOracle, "Action only allowed by Oracle contract");
        _;
    }

    modifier onlyUnopenedPacks(uint256 _packId) {
        require(token.isTokenFrozen(_packId) != true, "Action only allowed Unopened Packs");
        _;
    }

    function initialize(address _owner) public initializer {
        Ownable.initialize(_owner);
        packGumPerGeneration = [555, 725, 1000]; // 1,000,000,000 Reserved for Pack Gum
        endpoint = "https://crypto-cards.io/pack-info/";
    }

    function setContractAddresses(
        address _controller,
        address _oracle,
        CryptoCards _cards,
        CryptoCardsGum _gum,
        CryptoCardsLib _lib
    ) public onlyOwner {
        require(_controller != address(0), "Invalid controller address supplied");
        require(_oracle != address(0), "Invalid oracle address supplied");
        require(_cards != address(0), "Invalid cards address supplied");
        require(_gum != address(0), "Invalid gum address supplied");
        require(_lib != address(0), "Invalid lib address supplied");

        cryptoCardsController = _controller;
        cryptoCardsOracle = _oracle;
        cards = _cards;
        gum = _gum;
        lib = _lib;
    }

    function setContractController(address _controller) public onlyOwner {
        require(_controller != address(0), "Invalid address supplied");
        cryptoCardsController = _controller;
    }

    function setOracleAddress(address _oracle) public onlyOwner {
        require(_oracle != address(0), "Invalid address supplied");
        cryptoCardsOracle = _oracle;
    }

    function setErc721Token(CryptoCardsERC721 _token) public onlyOwner {
        require(_token != address(0), "Invalid address supplied");
        token = _token;
    }

    function setCardsAddress(CryptoCards _cards) public onlyOwner {
        require(_cards != address(0), "Invalid address supplied");
        cards = _cards;
    }

    function setGumAddress(CryptoCardsGum _gum) public onlyOwner {
        require(_gum != address(0), "Invalid address supplied");
        gum = _gum;
    }

    function setLibAddress(CryptoCardsLib _lib) public onlyOwner {
        require(_lib != address(0), "Invalid address supplied");
        lib = _lib;
    }

    function updateEndpoint(string _endpoint) public onlyOwner {
        endpoint = _endpoint;
    }

    function totalMintedPacks() public view returns (uint256) {
        return token.totalSupply();
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return token.balanceOf(_owner);
    }

    function packDataById(uint256 _packId) public view returns (string) {
        require(_packId >= 0 && _packId < token.totalSupply(), "Invalid packId supplied");
        return packsDataById[_packId];
    }

    function isPackOpened(uint256 _packId) public view returns (bool) {
        return token.isTokenFrozen(_packId);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        return token.tokenOfOwnerByIndex(_owner, _index);
    }

    function unclaimedGumOf(address _owner) public view returns (uint256) {
        return packGumByOwner[_owner];
    }

    function claimPackGum(address _to) public onlyController returns (uint256) {
        require(_to != address(0), "Invalid address supplied");
        require(packGumByOwner[_to] > 0, "No GUM to Claim");

        uint256 quantity = packGumByOwner[_to];
        gum.claimPackGum(_to, quantity);
        packGumByOwner[_to] = 0;
        return quantity;
    }

    function updatePackPrice(address _owner, uint256 _packId, uint256 _packPrice) public onlyController onlyUnopenedPacks(_packId) {
        require(_packId >= 0 && _packId < token.totalSupply(), "Invalid packId supplied");
        address packOwner = token.ownerOf(_packId);
        require(packOwner != address(0) && _owner == packOwner, "Invalid owner supplied or owner is not pack-owner");
        packSalePriceById[_packId] = _packPrice;
    }

    function transferPackForBuyer(address _receiver, address _owner, uint256 _packId, uint256 _pricePaid) public onlyController onlyUnopenedPacks(_packId) returns (uint256) {
        require(_packId >= 0 && _packId < token.totalSupply(), "Invalid packId supplied");
        address packOwner = token.ownerOf(_packId);
        require(packOwner != address(0) && _owner == packOwner, "Invalid owner supplied or owner is not pack-owner");
        require(_receiver != packOwner, "Cannot transfer pack to self");

        uint256 packPrice = packSalePriceById[_packId];
        require(packPrice > 0, "Pack is not for sale");
        require(_pricePaid >= packPrice, "Pack price is greater than the price paid");

        transferPack(packOwner, _receiver, _packId);

        return packPrice;
    }

    /**
     * @dev Mint pack
     * @param _to The address that will own the minted pack
     * @param _packData string String representation of the pack to be minted
     */
    function mintPack(address _to, string _packData, uint256 _packGeneration) public onlyOracle {
        uint256 packId = token.totalSupply();
        string memory packInfo = lib.uintToHexStr(packId);
        token.mintWithTokenURI(_to, packId, endpoint.toSlice().concat(packInfo.toSlice()));
        packsDataById[packId] = _packData;
        packGumByOwner[_to] = packGumByOwner[_to] + (packGumPerGeneration[_packGeneration-1] * (10**18));
    }

    /**
     * @dev Tokenize a pack by minting the card tokens within the pack
     * @param _packId uint256 Pack ID of the pack to be minted
     */
    function tokenizePack(address _opener, uint256 _packId) public onlyController onlyUnopenedPacks(_packId) returns (uint256[8]) {
        require(_packId >= 0 && _packId < token.totalSupply(), "Invalid packId supplied");
        address owner = token.ownerOf(_packId);
        require(owner != address(0) && _opener == owner, "opener must be owner of pack");

        // Tokenize Pack
        uint256[8] memory mintedCards;
        strings.slice memory s = packsDataById[_packId].toSlice();
        strings.slice memory d = ".".toSlice();
        for (uint i = 0; i < 8; i++) {
            mintedCards[i] = cards.mintCard(owner, s.split(d).toString());
        }

        // Mark Pack as Opened
        token.freezeToken(_packId);

        return mintedCards;
    }

    function transferPack(address _from, address _to, uint256 _packId) internal {
        require(_from != address(0), "Invalid from address supplied");
        require(_to != address(0), "Invalid to address supplied");

        resetPackValue(_packId);
        token.tokenTransfer(_from, _to, _packId);
    }

    function resetPackValue(uint256 _packId) internal {
        packSalePriceById[_packId] = 0;
    }
}

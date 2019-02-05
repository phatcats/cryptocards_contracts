/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2019 (c) Phat Cats, Inc.
 */

pragma solidity 0.4.24;

import "./strings.sol";
//import "github.com/Arachnid/solidity-stringutils/strings.sol";

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";

import "./CryptoCardsERC721.sol";
import "./CryptoCardsLib.sol";
import "./CryptoCardsGum.sol";
import "./CryptoCards.sol";


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
        require(msg.sender == cryptoCardsController);
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == cryptoCardsOracle);
        _;
    }

    function initialize(address _owner) public initializer {
        Ownable.initialize(_owner);
        packGumPerGeneration = [555, 725, 1000];
        endpoint = "https://crypto-cards.io/pack-info/";
    }

    function setContractController(address _controller) public onlyOwner {
        require(_controller != address(0));
        cryptoCardsController = _controller;
    }

    function setOracleAddress(address _oracle) public onlyOwner {
        require(_oracle != address(0));
        cryptoCardsOracle = _oracle;
    }

    function setErc721Token(CryptoCardsERC721 _token) public onlyOwner {
        require(_token != address(0));
        token = _token;
    }

    function setCardsAddress(CryptoCards _cards) public onlyOwner {
        require(_cards != address(0));
        cards = _cards;
    }

    function setGumAddress(CryptoCardsGum _gum) public onlyOwner {
        require(_gum != address(0));
        gum = _gum;
    }

    function setLibAddress(CryptoCardsLib _lib) public onlyOwner {
        require(_lib != address(0));
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
        require(_packId >= 0 && _packId < token.totalSupply());
        return packsDataById[_packId];
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        return token.tokenOfOwnerByIndex(_owner, _index);
    }

    function claimPackGum(address _to) public onlyController returns (uint256) {
        require(_to != address(0));
        require(packGumByOwner[_to] > 0, 'No GUM to Claim');

        uint256 quantity = packGumByOwner[_to];
        gum.claimPackGum(_to, quantity);
        packGumByOwner[_to] = 0;
        return quantity;
    }

    function updatePackPrice(address _owner, uint256 _packId, uint256 _packPrice) public onlyController {
        require(_packId >= 0 && _packId < token.totalSupply());
        address packOwner = token.ownerOf(_packId);
        require(packOwner != address(0) && _owner == packOwner);
        packSalePriceById[_packId] = _packPrice;
    }

    function transferPackForBuyer(address _receiver, address _owner, uint256 _packId, uint256 _pricePaid) public onlyController returns (uint256) {
        require(_packId >= 0 && _packId < token.totalSupply());
        address packOwner = token.ownerOf(_packId);
        require(packOwner != address(0) && _owner == packOwner && _receiver != packOwner);

        uint256 packPrice = packSalePriceById[_packId];
        require(packPrice > 0 && _pricePaid >= packPrice);

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
        packGumByOwner[_to] = packGumByOwner[_to] + packGumPerGeneration[_packGeneration-1];
    }

    /**
     * @dev Tokenize a pack by minting the card tokens within the pack
     * @param _packId uint256 Pack ID of the pack to be minted
     */
    function tokenizePack(address _opener, uint256 _packId) public onlyController returns (uint256[8]) {
        require(_packId >= 0 && _packId < token.totalSupply());
        address owner = token.ownerOf(_packId);
        require(owner != address(0) && _opener == owner);

        // Tokenize Pack
        uint256[8] memory mintedCards;
        strings.slice memory s = packsDataById[_packId].toSlice();
        strings.slice memory d = ".".toSlice();
        for (uint i = 0; i < 8; i++) {
            mintedCards[i] = cards.mintCard(owner, s.split(d).toString());
        }

        // Destroy owned pack
        delete packsDataById[_packId];
//        _burn(owner, _packId);             TODO
        return mintedCards;
    }

    function transferPack(address _from, address _to, uint256 _packId) internal {
        require(_from != address(0));
        require(_to != address(0));

        resetPackValue(_packId);
        token.tokenTransfer(_from, _to, _packId);
    }

    function resetPackValue(uint256 _packId) internal {
        packSalePriceById[_packId] = 0;
    }
}

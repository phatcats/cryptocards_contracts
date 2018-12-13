/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2018 (c) Phat Cats, Inc.
 */

pragma solidity 0.4.24;

import "./Helpers.sol";
import "./strings.sol";
//import "github.com/Arachnid/solidity-stringutils/strings.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
//import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./pausable.sol";
import "./erc721.sol";


contract CryptoCards {
    function mintCard(address _to, string _cardData) public returns (uint256);
}


contract CryptoCardPacks is ERC721Token, Ownable, Helpers {
    using SafeMath for uint256;
    using strings for *;

    // Info-URI Endpoint
    string internal endpoint = "https://www.crypto-cards.io/pack-info/";

    // Minted Packs Count
    uint256 internal mintedPacks;

    // Contract Controller
    address internal contractController;  // Points to CryptoCardsController Contract

    // Mapping from token ID to pack-data
    mapping(uint256 => string) internal packsDataById;
    mapping(uint256 => uint256) internal packSalePriceById;
//    mapping(uint256 => bool) internal openedPacks;

    CryptoCards internal CryptoCards_;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyController() {
        require(msg.sender == contractController);
        _;
    }

    /**
     * @dev todo..
     */
    constructor() ERC721Token("Crypto-Cards - Packs", "PACKS") public {

    }

    /**
     * @dev todo..
     */
    function initialize(address _controller, address _cardsToken) public onlyOwner {
        contractController = _controller;
        CryptoCards_ = CryptoCards(_cardsToken);
    }

    /**
     * @dev todo..
     */
    function setContractController(address _controller) public onlyOwner {
        contractController = _controller;
    }

    /**
     * @dev todo..
     */
    function updateEndpoint(string _endpoint) public onlyOwner {
        endpoint = _endpoint;
    }

    /**
     * @dev todo..
     */
    function totalMintedPacks() public view returns (uint256) {
        return mintedPacks;
    }

    /**
     * @dev todo..
     */
    function packDataById(uint256 _packId) public view returns (string) {
        require(_packId >= 0 && _packId < mintedPacks);
        return packsDataById[_packId];
    }

    /**
     * @dev todo..
     */
    function updatePackPrice(address _owner, uint256 _packId, uint256 _packPrice) public onlyController {
        require(_packId >= 0 && _packId < mintedPacks);
        address packOwner = tokenOwner[_packId];
        require(packOwner != address(0) && _owner == packOwner);
        packSalePriceById[_packId] = _packPrice;
    }

    /**
     * @dev todo..
     */
    function transferPackForBuyer(address _purchaser, address _owner, uint256 _packId, uint256 _pricePaid) public onlyController returns (uint256) {
        require(_packId >= 0 && _packId < mintedPacks);
        address packOwner = tokenOwner[_packId];
        require(packOwner != address(0) && _owner == packOwner && _purchaser != packOwner);

        uint256 packPrice = packSalePriceById[_packId];
        require(packPrice > 0 && _pricePaid >= packPrice);

        transferPack(packOwner, _purchaser, _packId);

        return packPrice;
    }

    /**
     * @dev Mint pack
     * @param _to The address that will own the minted pack
     * @param _packData string String representation of the pack to be minted
     */
    function mintPack(address _to, string _packData) public onlyController {
        uint256 packId = mintedPacks;
        _mint(_to, packId);

        packsDataById[packId] = _packData;

        string memory packInfo = uintToHexStr(packId);
        _setTokenURI(packId, endpoint.toSlice().concat(packInfo.toSlice()));
        mintedPacks++;
    }

    /**
     * @dev Tokenize a pack by minting the card tokens within the pack
     * @param _packId uint256 Pack ID of the pack to be minted
     */
    function tokenizePack(address _opener, uint256 _packId) public onlyController returns (uint256[8]) {
        require(_packId >= 0 && _packId < mintedPacks);
        address owner = tokenOwner[_packId];
        require(owner != address(0) && _opener == owner);

        // Tokenize Pack
        uint256[8] memory mintedCards;
        strings.slice memory s = packsDataById[_packId].toSlice();
        strings.slice memory d = ".".toSlice();
        for (uint i = 0; i < 8; i++) {
            mintedCards[i] = CryptoCards_.mintCard(owner, s.split(d).toString());
        }
//        openedPacks[_packId] = true;

        // Destroy owned pack
        delete packsDataById[_packId];
        _burn(owner, _packId);

        return mintedCards;
    }

    /**
     * @dev todo..
     */
    function transferPack(address _from, address _to, uint256 _packId) internal {
        require(_from != address(0));
        require(_to != address(0));

        resetPackValue(_packId);
        clearApproval(_from, _packId);
        removeTokenFrom(_from, _packId);
        addTokenTo(_to, _packId);
    }

    /**
     * @dev todo..
     */
    function resetPackValue(uint256 _packId) private {
        packSalePriceById[_packId] = 0;
    }
}

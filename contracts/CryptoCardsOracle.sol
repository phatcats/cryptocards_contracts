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
import "./usingOraclize.sol";

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";

import "./CryptoCardsLib.sol";
import "./CryptoCardPacks.sol";
import "./CryptoCardsController.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsOracle is Ownable, usingOraclize {
    using strings for *;

    CryptoCardsLib internal cryptoCardsLib;
    CryptoCardPacks internal cryptoCardPacks;
    CryptoCardsController internal cryptoCardsController;

    uint256 internal oracleGasLimit;
    uint256 internal nextGeneration;

    mapping(bytes32=>address) internal oracleIdToOwner;
    mapping(bytes32=>bytes16) internal oracleIdToUUID;
    mapping(bytes32=>bool) internal oracleIds;
    mapping(bytes16=>bool) internal uuids;

    string internal apiEndpoint;

    modifier onlyController() {
        require(msg.sender == address(cryptoCardsController), "Action only allowed by Controller contract");
        _;
    }

    function initialize(address _owner) public initializer {
        Ownable.initialize(_owner);

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Local Only
//        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
//        oraclize_setNetwork(networkID_testnet);
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        oraclize_setCustomGasPrice(10000000000); // 10 gwei
        oracleGasLimit = 400000;                 // wei
        nextGeneration = 1;                      // Valid gens: 1, 2, or 3.   4 = Sold Out
    }

    function setContractAddresses(
        CryptoCardsController _controller,
        CryptoCardPacks _packs,
        CryptoCardsLib _lib
    ) public onlyOwner {
        require(_controller != address(0), "Invalid controller address supplied");
        require(_packs != address(0), "Invalid packs address supplied");
        require(_lib != address(0), "Invalid lib address supplied");

        cryptoCardsController = _controller;
        cryptoCardPacks = _packs;
        cryptoCardsLib = _lib;
    }

    function setContractController(CryptoCardsController _controller) public onlyOwner {
        require(_controller != address(0), "Invalid address supplied");
        cryptoCardsController = _controller;
    }

    function setPacksAddress(CryptoCardPacks _packs) public onlyOwner {
        require(_packs != address(0), "Invalid address supplied");
        cryptoCardPacks = _packs;
    }

    function setLibAddress(CryptoCardsLib _lib) public onlyOwner {
        require(_lib != address(0), "Invalid address supplied");
        cryptoCardsLib = _lib;
    }

    function updateApiEndpoint(string _endpoint) public onlyOwner {
        apiEndpoint = _endpoint;
    }

    function updateOracleGasPrice(uint _wei) public onlyOwner payable {
        oraclize_setCustomGasPrice(_wei);
    }

    function updateOracleGasLimit(uint _wei) public onlyOwner {
        oracleGasLimit = _wei;
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function sweepUnusedOracleGas() public onlyOwner {
        address owner = msg.sender;
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract balance must be greater than zero");
        owner.transfer(balance);
    }

    function isValidUuid(bytes16 _uuid) public view onlyController returns (bool) {
        return !uuids[_uuid];
    }

    function getNextGeneration() public view onlyController returns (uint256) {
        return nextGeneration;
    }

    function getGasReserve() public onlyController returns (uint256) {
        return oraclize_getPrice("URL", oracleGasLimit);
    }

    function getNewPack(address _receiver, uint256 _gasReserve, bytes16 _uuid) public onlyController payable {
        if (_gasReserve > address(this).balance) {
            cryptoCardsController.receivedPackError(_receiver, _uuid, "100");  // Insufficient Funds for Oracle Error
        } else {
            bytes32 queryId = oraclize_query("URL", apiEndpoint, oracleGasLimit);
            uuids[_uuid] = true;
            oracleIdToOwner[queryId] = _receiver;
            oracleIdToUUID[queryId] = _uuid;
            oracleIds[queryId] = true;
        }
    }

    function __callback(bytes32 _queryId, string _result) public {
        require(oracleIds[_queryId], "Invalid oracle id");
        require(msg.sender == oraclize_cbAddress(), "Invalid oracle origin");
        require(bytes(_result).length > 0, "Invalid oracle response");

        address receiver = oracleIdToOwner[_queryId];

        strings.slice memory s = _result.toSlice();
        // Code 0: Error
        // Code 1 - 3: Next Generation
        // Code 4: Sold-out
        uint256 responseCode = cryptoCardsLib.strToUint(s.split(".".toSlice()).toString());

        // Check for Error from API
        if (responseCode == 0) {
            cryptoCardsController.receivedPackError(receiver, oracleIdToUUID[_queryId], _result);  // API Error
        } else {
            // Get Pack Data
            string memory packData = s.toString();
            uint256 packId = cryptoCardPacks.totalMintedPacks();
            cryptoCardPacks.mintPack(receiver, packData, nextGeneration);
            cryptoCardsController.receivedNewPack(receiver, oracleIdToUUID[_queryId], packId);

            // Get Next Generation of Cards
            nextGeneration = responseCode;
        }
//        delete uuids[oracleIdToUUID[_queryId]];
//        delete oracleIdToOwner[_queryId];
//        delete oracleIdToUUID[_queryId];
        delete oracleIds[_queryId];
    }
}

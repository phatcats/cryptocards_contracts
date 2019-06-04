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

import "./strings.sol";
import "./usingOraclize.sol";

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";

import "./CryptoCardsLib.sol";
import "./CryptoCardsPacks.sol";
import "./CryptoCardsGum.sol";
import "./CryptoCardsController.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsOracle is Ownable, usingOraclize {
    using strings for *;

    //
    // Storage
    //
    CryptoCardsLib internal cryptoCardsLib;
    CryptoCardsPacks internal cryptoCardsPacks;
    CryptoCardsGum internal cryptoCardsGum;
    CryptoCardsController internal cryptoCardsController;

    uint256 internal oracleGasLimit;

    mapping(bytes32=>address) internal oracleIdToOwner;
    mapping(bytes32=>bytes16) internal oracleIdToUUID;
    mapping(bytes32=>bool) internal oracleIds;
    mapping(bytes16=>bool) internal uuids;

    string internal apiEndpoint;

    //
    // Events
    //
    event ReceivedNewPack(address indexed receiver, bytes16 uuid, uint256 packId);
    event PackError      (address indexed receiver, bytes16 uuid, uint256 errorCode);

    //
    // Modifiers
    //
    modifier onlyController() {
        require(msg.sender == address(cryptoCardsController), "Action only allowed by Controller contract");
        _;
    }

    //
    // Initialize
    //
    function initialize(address _owner) public initializer {
        Ownable.initialize(_owner);

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Local Only
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        oraclize_setNetwork(networkID_testnet);
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        oraclize_setCustomGasPrice(10000000000); // 10 gwei
        oracleGasLimit = 400000;                 // wei
    }

    //
    // Only Controller
    //

    function isValidUuid(bytes16 _uuid) public view onlyController returns (bool) {
        return !uuids[_uuid];
    }

    function getGasReserve() public onlyController returns (uint256) {
        return oraclize_getPrice("URL", oracleGasLimit);
    }

    function getNewPack(address receiver, uint256 gasReserve, bytes16 uuid) public onlyController payable {
        if (gasReserve > address(this).balance) {
            emit PackError(receiver, uuid, uint256(100));  // Insufficient Funds for Oracle Error
        } else {
            bytes32 queryId = oraclize_query("URL", apiEndpoint, oracleGasLimit);
            uuids[uuid] = true;
            oracleIdToOwner[queryId] = receiver;
            oracleIdToUUID[queryId] = uuid;
            oracleIds[queryId] = true;
        }
    }

    function __callback(bytes32 _queryId, string _result) public {
        require(oracleIds[_queryId], "Invalid oracle id");
        require(msg.sender == oraclize_cbAddress(), "Invalid oracle origin");
        require(bytes(_result).length > 0, "Invalid oracle response");

        address receiver = oracleIdToOwner[_queryId];

        strings.slice memory s = _result.toSlice();
        // Code 0 = All-Good - Pack Generated
        // Code 1+ = Error Code
        uint256 responseCode = cryptoCardsLib.strToUint(s.split(".".toSlice()).toString());

        // Check for Error from API
        if (responseCode > 0) {
            emit PackError(receiver, oracleIdToUUID[_queryId], responseCode);  // API Error
        } else {
            // Mint Pack and Transfer GUM Reward
            string memory packData = s.toString();
            uint256 packId = cryptoCardsPacks.mintPack(receiver, packData);
            cryptoCardsGum.transferPackGum(receiver, 1);
            emit ReceivedNewPack(receiver, oracleIdToUUID[_queryId], packId);
        }
        delete uuids[oracleIdToUUID[_queryId]];
        delete oracleIdToOwner[_queryId];
        delete oracleIdToUUID[_queryId];
        delete oracleIds[_queryId];
    }

    //
    // Only Owner
    //

    function setContractController(CryptoCardsController _controller) public onlyOwner {
        require(_controller != address(0), "Invalid address supplied");
        cryptoCardsController = _controller;
    }

    function setPacksAddress(CryptoCardsPacks _packs) public onlyOwner {
        require(_packs != address(0), "Invalid address supplied");
        cryptoCardsPacks = _packs;
    }

    function setGumAddress(CryptoCardsGum _gum) public onlyOwner {
        require(_gum != address(0), "Invalid address supplied");
        cryptoCardsGum = _gum;
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

    //    function contractBalance() public view returns (uint256) {
    //        return address(this).balance;
    //    }
    //
    //    function sweepUnusedOracleGas() public onlyOwner {
    //        address owner = msg.sender;
    //        uint256 balance = address(this).balance;
    //        require(balance > 0, "Contract balance must be greater than zero");
    //        owner.transfer(balance);
    //    }
}

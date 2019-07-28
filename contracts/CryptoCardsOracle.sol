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

pragma solidity 0.5.2;

import "./usingOraclize.sol";

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";

import "./CryptoCardsPacks.sol";
import "./CryptoCardsController.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsOracle is Ownable, usingOraclize {

    //
    // Storage
    //
    CryptoCardsPacks internal cryptoCardsPacks;
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
    event ReceivedNewPack(address indexed receiver, bytes16 uuid, uint256 packId, string packData);
    event PackError      (address indexed receiver, bytes16 uuid, uint8 errorCode);

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
//        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
//        oraclize_setNetwork(networkID_testnet);
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        oraclize_setCustomGasPrice(10000000000);  // 10 gwei
        oracleGasLimit = 310000;                  // wei
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
            emit PackError(receiver, uuid, uint8(100));  // Insufficient Funds for Oracle Error
        } else {
            string memory apiParams = string(abi.encodePacked('{"uuid":"', uuid, '"}'));
            bytes32 queryId = oraclize_query("URL", apiEndpoint, apiParams, oracleGasLimit);

            // Not working due to address
//            string memory apiParams = string(abi.encodePacked('{"owner":"', receiver, '","uuid":"', uuid, '"}'));
//            bytes32 queryId = oraclize_query("URL", apiEndpoint, apiParams, oracleGasLimit);

            uuids[uuid] = true;
            oracleIdToOwner[queryId] = receiver;
            oracleIdToUUID[queryId] = uuid;
            oracleIds[queryId] = true;
        }
    }

    function __callback(bytes32 _queryId, string memory _result) public {
        require(oracleIds[_queryId], "Invalid oracle id");
        require(msg.sender == oraclize_cbAddress(), "Invalid oracle origin");
        require(bytes(_result).length > 0, "Invalid oracle response");

        address receiver = oracleIdToOwner[_queryId];

        // Code 0 = All-Good - Pack Generated
        // Code 1+ = Error Code
        uint8 responseCode = _getResponseCode(_result);

        // Check for Error from API
        if (responseCode > 0) {
            emit PackError(receiver, oracleIdToUUID[_queryId], responseCode);  // API Error
        } else {
            // Mint Pack and Transfer GUM Reward
            uint256 packId = cryptoCardsPacks.mintPack(receiver, _result);
            emit ReceivedNewPack(receiver, oracleIdToUUID[_queryId], packId, _result);
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
        require(address(_controller) != address(0), "Invalid address supplied");
        cryptoCardsController = _controller;
    }

    function setPacksAddress(CryptoCardsPacks _packs) public onlyOwner {
        require(address(_packs) != address(0), "Invalid address supplied");
        cryptoCardsPacks = _packs;
    }

    function updateApiEndpoint(string memory _endpoint) public onlyOwner {
        apiEndpoint = _endpoint;
    }

    function updateOracleGasPrice(uint _wei) public onlyOwner payable {
        oraclize_setCustomGasPrice(_wei);
    }

    function updateOracleGasLimit(uint _wei) public onlyOwner {
        oracleGasLimit = _wei;
    }

    //
    // Private
    //

    function _getResponseCode(string memory str) internal pure returns (uint8) {
        bytes memory b = bytes(str);
        return uint8(b[0]) - 48;
    }
}

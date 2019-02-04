pragma solidity ^0.4.24;

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/token/ERC721/StandaloneERC721.sol";


/**
 * @title Crypto-Cards ERC721 Token
 * ERC721-compliant token representing individual Packs/Cards
 */
contract CryptoCardsERC721 is StandaloneERC721 {
    function initialize(string _name, string _symbol, address[] _minters, address[] _pausers) public initializer {
        StandaloneERC721.initialize(_name, _symbol, _minters, _pausers);
    }

    function tokenTransfer(address _from, address _to, uint256 _tokenId) public onlyMinter {
        require(_from != address(0) && _to != address(0));

        _clearApproval(_from, _tokenId);
        _removeTokenFrom(_from, _tokenId);
        _addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }
}

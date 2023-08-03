// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tarti is ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _currentTokenId;
    mapping(uint8 => uint256) public artistNextArtId;

    mapping(uint8 => mapping(uint256 => uint256)) private _artByArtist;
    mapping(uint256 => uint8) public artCreators;

    bytes private constant _newMetadataCid =
        "QmVv7nzTAY8gZEVXGWbxEeGRHhwXzcL2C1XNaYVBoWhvUA";

    bytes private constant _newMetadataUri =
        "ipfs://QmVv7nzTAY8gZEVXGWbxEeGRHhwXzcL2C1XNaYVBoWhvUA";

    bytes private constant _inProcessMetadataCid =
        "QmbPGGNUY8zfyEjr1rWTnEFfpNoyppWrutNWCgZYu3WM4F";

    bytes private constant _inProcessMetadataUri =
        "ipfs://QmbPGGNUY8zfyEjr1rWTnEFfpNoyppWrutNWCgZYu3WM4F";

    constructor() ERC721("Tarti Art", "TARTI") {}

    event PermanentURI(string _value, uint256 indexed _id);

    function newArt(
        address crHolder,
        uint8 artistId
    ) public onlyOwner returns (uint256) {
        _currentTokenId.increment();
        uint256 newArtId = _currentTokenId.current();
        _artByArtist[artistId][artistNextArtId[artistId]] = newArtId;
        artistNextArtId[artistId]++;
        artCreators[newArtId] = artistId;
        _safeMint(crHolder, newArtId);
        _setTokenURI(newArtId, string(abi.encodePacked(_newMetadataCid)));

        return newArtId;
    }

    //this can be used to iterate through the art of a specific artist
    function artByArtist(
        uint8 artistId,
        uint256 artOrdinal
    ) public view returns (uint256) {
        return _artByArtist[artistId][artOrdinal];
    }

    function setCreationStarted(uint256 tokenId) public onlyOwner {
        //Don't allow the URI to ever change once it is set!
        //Can't compare strings, so lets compare their hashes
        bytes32 tokenUriBytesHash = keccak256(bytes(tokenURI(tokenId)));
        require(
            tokenUriBytesHash == keccak256(abi.encodePacked(_newMetadataUri)),
            "tartinotnew"
        );

        _setTokenURI(tokenId, string(abi.encodePacked(_inProcessMetadataCid)));
    }

    function setCreated(uint256 tokenId, bytes calldata cid) public onlyOwner {
        //Don't allow the URI to ever change once it is set!
        //Can't compare strings, so lets compare their hashes
        bytes32 tokenUriBytesHash = keccak256(bytes(tokenURI(tokenId)));
        require(
            tokenUriBytesHash ==
                keccak256(abi.encodePacked(_inProcessMetadataUri)),
            "tartinotstarted"
        );

        //@todo would it be cheaper to calc twice instead of storing?
        string memory newUri = string(abi.encodePacked(cid));
        _setTokenURI(tokenId, newUri);
        emit PermanentURI(newUri, tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

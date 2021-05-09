// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tarti is ERC721URIStorage, ERC721Enumerable, Ownable {
    uint256 private _nextArtId;
    mapping (uint256 => uint8) public _createdBy;
    mapping (uint8 => uint256) public _artistNextArtId;
    mapping(uint8 => mapping(uint256 => uint256)) private _artByArtist;

    constructor(address artistContract) ERC721("Tarti Art", "TARTI") {
        transferOwnership(artistContract);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://tartscoin.com/tarts/";
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        return ERC721URIStorage._burn(tokenId);
    }

    function newArt(address crHolder, uint8 artistId, string memory ipfsId) 
    public onlyOwner returns (uint256) {

        require (_nextArtId < 1000000, "contracteol");
        uint256 newArtId = _nextArtId;
        _safeMint(crHolder, newArtId);
        _setTokenURI(newArtId, ipfsId); //setter is part of Zeppelen contract. All it does is check that the token exists and then sets a value for a normal mapping
        _createdBy[newArtId] = artistId;
        _artByArtist[artistId][_artistNextArtId[artistId]] = newArtId;
        _nextArtId++;
        _artistNextArtId[artistId]++;

        // (bool ethSent, bytes memory sendEthData) = payable(owner()).call{value: msg.value}("");
        // require(ethSent, "Unable to transfer payment to artist contract");

        return newArtId;
    }

    function artByIndex(uint256 index) public view returns (uint256) {
        require (index < _nextArtId, "specified art doesn't exist");
        return super.tokenByIndex(index);
    }

    //this can be used to iterate through the art of a specific artist
    function artByArtist(uint8 artistId, uint256 artOrdinal) public view returns (uint256) {
        return artByIndex(_artByArtist[artistId][artOrdinal]);
    }

    //figure out how to ensure that only the owner can transfer it
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }
}

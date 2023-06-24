// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tarti.sol";

contract Tartist is ERC721URIStorage, ERC721Enumerable, PullPayment, Ownable {
    using Counters for Counters.Counter;

    uint256 public constant MINT_TARTIST_PRICE = 0.18 ether;
    uint256 public constant MINT_TARTI_PRICE = 0.048 ether;

    Counters.Counter private _currentTokenId;

    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;
    mapping(bytes2 => bool) public allTraits;
    mapping(bytes32 => bool) public usedTraitComboHashes;
    mapping(uint256 => bytes) public botTraits;
    mapping(uint256 => string[]) public botTraitDynValues;
    mapping(uint256 => uint8[]) public botTraitDominance;

    address private _tartiAddr;

    constructor() ERC721("Tarti Artist", "TARTIST") {
        baseTokenURI = "ipfs://ipfs.tarti.eth/tarti/artists/";
    }

    function giveBirth(
        address recipient,
        bytes memory traits,
        string[] memory dynamicTraitValues,
        uint8[] memory traitDominance
    ) public payable returns (uint256) {
        require(
            msg.value == MINT_TARTIST_PRICE,
            "Transaction value did not equal the mint price"
        );
        require(traits.length < 100, "Too many traits");
        require(dynamicTraitValues.length < 100, "Too many trait values");
        require(traitDominance.length < 100, "Too many trait dominance");
        require(traits.length % 2 == 0, "Invalid trait length");

        // when we implement the allTraits/AddTraits here is how they should be keyed
        // allTraits["aa"] = true;
        // allTraits["bb"] = true;
        // allTraits["cc"] = true;

        //check that the passed traits are valid
        //every two bytes identifes a trait
        for (uint256 i = 0; i < traits.length; i += 2) {
            require(
                allTraits[bytes2(bytes.concat(traits[i], traits[i + 1]))] ==
                    true,
                "Invalid trait specified"
            );
        }

        bytes memory dynTraitValuesBytes;
        for (uint256 i = 0; i < dynamicTraitValues.length; i++) {
            dynTraitValuesBytes = abi.encodePacked(
                dynTraitValuesBytes,
                dynamicTraitValues[i]
            );
        }
        bytes32 botTraitsHash = keccak256(
            bytes.concat(traits, dynTraitValuesBytes)
        );
        require(
            usedTraitComboHashes[botTraitsHash] != true,
            "Bot genetics are not unique enough"
        );

        usedTraitComboHashes[botTraitsHash] = true;
        _currentTokenId.increment();
        uint256 newItemId = _currentTokenId.current();
        botTraits[newItemId] = traits;
        botTraitDynValues[newItemId] = dynamicTraitValues;
        botTraitDominance[newItemId] = traitDominance;
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function newArt(uint8 artistId) public payable {
        //address canot be blank
        require(_tartiAddr != address(0), "tartscontractnotset");
        require(msg.value == MINT_TARTIST_PRICE, "must send commission"); //.01 eth

        //call newArt on the Tarti contract
        //Tarti only allows this contract to call that method
        //Tell the new art method who the artist is

        //First check that the caller is the owner of the artist
        //if an artist has no owner, I forget who is allowed to use it? (maybe anyone but only if I get commissions)
        //thats a good idea. For ownerless i get commissions. for owned I dont

        //norights = specified artist is not contractually obligated, nor even allowed, to make any art for you.
        require(msg.sender == ownerOf(artistId), "norights");

        //use the art contract to create a new Tart token
        //Trait engine will see the new Art on the blockchain and create the art
        //the art package url will be based on the Tart tokenId
        //we will own the dns of whatever we use for IPFS so we can pre generate here and guarantee to have it

        Tarti tarti = Tarti(_tartiAddr);

        tarti.newArt(msg.sender, artistId);

        //original artistastist gets the commission
        //for now that is always the owner of the artist contract but we night change that
        (bool ethSent, bytes memory sendEthData) = payable(owner()).call{
            value: msg.value
        }("");
        require(ethSent, "could not pay the owner");
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setTartiAddr(address tartiAddr) public onlyOwner {
        _tartiAddr = tartiAddr;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @dev Overridden in order to make it an onlyOwner function
    function withdrawPayments(
        address payable payee
    ) public virtual override onlyOwner {
        super.withdrawPayments(payee);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        //I have a hunch the default impleemattn does this exact same thing so maybe we just use super.tokenuri??
        return string.concat(baseTokenURI, Strings.toString(tokenId));
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

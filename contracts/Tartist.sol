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
    bytes private constant _newMetadataCid =
        "Qmdn9VDMcfXrP9VEYB5g5qSEAZsU6JZs69d9qynETPpC6C";
    bytes private constant _inProcessMetadataCid =
        "QmRujo769ovCxzoBGeisQkUWn28xv1Wj1Z86jWpmKDfZBM";
    mapping(bytes32 => bool) private _usedTraitComboHashes;

    uint256[] public allTraits;
    mapping(uint256 => uint256[]) public botTraits;
    mapping(uint256 => uint256[]) public botTraitDominances;
    mapping(uint256 => string) public availableTraits;
    mapping(uint256 => string[]) public botTraitValues;

    Counters.Counter private _currentTokenId;
    address private _tartiAddr;

    event PermanentURI(string _value, uint256 indexed _id);

    constructor() ERC721("Tarti Artist", "TARTIST") {}

    /**
        `traitName` will either be:
        - The name of the Trait class (ie MusicProducer)
        - The name of the Trait with dot then the name of the trait prop appended (ie DynMusicProductionStyle.FavoriteKeys)
        -- In this case the TraitAI trait being added to the bot is DynMusicProductionStyle, 
        -- and the prop the value wll map to is FavoriteKeys.
        -- This flat structure will be nice for the NFT metadata to be standard and easy.
        -- When it gets sent into the TraitHttpIO we will need to pull out the props and put them all beneath the same single trait.
     */
    function addTrait(
        uint256 traitCode,
        string memory traitName
    ) public onlyOwner {
        require(
            bytes(availableTraits[traitCode]).length == 0,
            "Trait already exists"
        );
        availableTraits[traitCode] = traitName;
        allTraits.push(traitCode);
    }

    function cancelTrait(uint256 traitCode) public onlyOwner {
        availableTraits[traitCode] = "";

        //doesnt provide any use to remove it from allTraits, waste of gas. So we will just leave it.
    }

    function getAllTraits() external view returns (uint256[] memory) {
        return allTraits;
    }

    function giveBirth(
        address recipient,
        uint256[] memory traits,
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

        //check that the passed traits are valid
        for (uint256 i = 0; i < traits.length; i++) {
            require(
                bytes(availableTraits[traits[i]]).length > 0,
                "Invalid trait specified"
            );
        }

        //can optimize the heck out of this stuff but resisting for now.
        //Dont set storage vars in loops!
        bytes memory traitBytes;
        for (uint256 i = 0; i < traits.length; i++) {
            traitBytes = abi.encodePacked(traitBytes, traits[i]);
        }

        bytes memory dynTraitValuesBytes;
        for (uint256 i = 0; i < dynamicTraitValues.length; i++) {
            dynTraitValuesBytes = abi.encodePacked(
                dynTraitValuesBytes,
                dynamicTraitValues[i]
            );
        }
        bytes32 botTraitsHash = keccak256(
            bytes.concat(traitBytes, dynTraitValuesBytes)
        );
        require(
            _usedTraitComboHashes[botTraitsHash] != true,
            "Bot genetics are not unique enough"
        );

        _usedTraitComboHashes[botTraitsHash] = true;
        _currentTokenId.increment();
        uint256 newItemId = _currentTokenId.current();
        botTraits[newItemId] = traits;
        botTraitValues[newItemId] = dynamicTraitValues;
        botTraitDominances[newItemId] = traitDominance;
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, string(abi.encodePacked(_newMetadataCid)));
        return newItemId;
    }

    function newArt(uint8 artistId) public payable returns (uint256) {
        //address canot be blank
        require(_tartiAddr != address(0), "tarticontractnotset");
        require(msg.value == MINT_TARTI_PRICE, "must send commission"); //.01 eth

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

        return tarti.newArt(msg.sender, artistId);
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function contractURI() public pure returns (string memory) {
        return "http://tartipublicfiles.tartiart.com/Tartist.metadata.json";
    }

    function setTartiAddr(address tartiAddr) public onlyOwner {
        _tartiAddr = tartiAddr;
    }

    function setCreationStarted(
        uint256 tokenId,
        bool onTarti
    ) public onlyOwner {
        if (onTarti) {
            require(_tartiAddr != address(0), "tarticontractnotset");
            Tarti tarti = Tarti(_tartiAddr);
            return tarti.setCreationStarted(tokenId);
        }
        _setTokenURI(tokenId, string(abi.encodePacked(_inProcessMetadataCid)));
    }

    function setCreated(
        uint256 tokenId,
        bytes calldata cid,
        bool onTarti
    ) public onlyOwner {
        if (onTarti) {
            require(_tartiAddr != address(0), "tarticontractnotset");
            Tarti tarti = Tarti(_tartiAddr);
            return tarti.setCreated(tokenId, cid);
        }
        //Don't allow the URI to ever change once it is set!
        //We ensure that the current URL is one of the default hashes.
        //If its not, that means its already been set, so we will not reset it in that case.
        //bytes32 tokenUriBytesHash = keccak256(bytes(tokenURI(tokenId))); //cant compare strings so lets compare hashes of strings
        // if (
        //     tokenUriBytesHash == keccak256(abi.encodePacked('ipfs://', _newMetadataCid)) ||
        //     tokenUriBytesHash == keccak256(abi.encodePacked('ipfs://', _inProcessMetadataCid))
        // ) {
        string memory newUri = string(abi.encodePacked(cid));
        _setTokenURI(tokenId, newUri);
        emit PermanentURI(newUri, tokenId);
        // }
    }

    function getTraits(
        uint256 tokenId
    ) external view returns (uint256[] memory) {
        return botTraits[tokenId];
    }

    function getTraitValues(
        uint256 tokenId
    ) external view returns (string[] memory) {
        return botTraitValues[tokenId];
    }

    function getTraitDominances(
        uint256 tokenId
    ) external view returns (uint256[] memory) {
        return botTraitDominances[tokenId];
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

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }
}

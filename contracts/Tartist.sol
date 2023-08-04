// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tarti.sol";

contract Tartist is ERC721URIStorage, ERC721Enumerable, PullPayment, Ownable {
    using Counters for Counters.Counter;

    uint256 public constant MINT_TARTIST_PRICE = 0.17 ether;
    uint256 public constant MINT_TARTI_PRICE = 0.047 ether;
    bytes private constant _newMetadataCid =
        "QmYKXrpFmABTH7VwfMWvXXRtMJWDcTTmB3vQXSSd2rEkYR";
    bytes private constant _newMetadataUri =
        "ipfs://QmYKXrpFmABTH7VwfMWvXXRtMJWDcTTmB3vQXSSd2rEkYR";
    bytes private constant _inProcessMetadataCid =
        "QmXUHvDvfFkk6f4GeiX5tpENh2aAyHYwp5BuzEhCTo79kF";
    bytes private constant _inProcessMetadataUri =
        "ipfs://QmXUHvDvfFkk6f4GeiX5tpENh2aAyHYwp5BuzEhCTo79kF";
    mapping(bytes32 => bool) private _usedTraitComboHashes;

    uint256[] public allTraits;
    mapping(string => uint256) private _allTraitsByName;
    mapping(uint256 => uint256[]) public botTraits;
    mapping(uint256 => uint256[]) public botTraitDominances;
    mapping(uint256 => string) public availableTraits;
    mapping(uint256 => string[]) public botTraitValues;

    //Tartist owner can set to greater than zero, allowing other to use their Tartist to make art
    mapping(uint256 => uint256) public tartiRoyaltyRate;

    Counters.Counter private _currentTokenId;
    address private _tartiAddr;

    event PermanentURI(string _value, uint256 indexed _id);

    constructor() ERC721("Tarti Artist", "TARTIST") {}

    /**
    @dev
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
        require(bytes(availableTraits[traitCode]).length == 0, "traitiddup");
        require(_allTraitsByName[traitName] == 0, "traitdup");
        availableTraits[traitCode] = traitName;
        _allTraitsByName[traitName] = traitCode;
        allTraits.push(traitCode);
    }

    function cancelTrait(uint256 traitCode) public onlyOwner {
        _allTraitsByName[availableTraits[traitCode]] = 0;
        availableTraits[traitCode] = "";
    }

    function getAllTraits() external view returns (uint256[] memory) {
        return allTraits;
    }

    /**
    Mint a TARTIST token
    This function `giveBrith` should be used in place of the traditional `mintTo`. 
    */
    function giveBirth(
        address recipient,
        uint256[] memory traits,
        string[] memory dynamicTraitValues,
        uint8[] memory traitDominance
    ) public payable returns (uint256) {
        require(msg.value == MINT_TARTIST_PRICE, "missingcommission");
        require(traits.length < 100, "toomanytraits");
        require(dynamicTraitValues.length < 100, "toomanytraitvals");
        require(traitDominance.length < 100, "toomanytraitdoms");

        for (uint256 i = 0; i < traits.length; i++) {
            require(
                bytes(availableTraits[traits[i]]).length > 0,
                "invalidtrait"
            );
        }

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
        require(_usedTraitComboHashes[botTraitsHash] != true, "geneticcopy");

        _usedTraitComboHashes[botTraitsHash] = true;
        _currentTokenId.increment();
        uint256 newItemId = _currentTokenId.current();
        botTraits[newItemId] = traits;
        botTraitValues[newItemId] = dynamicTraitValues;
        botTraitDominances[newItemId] = traitDominance;
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, string(abi.encodePacked(_newMetadataCid)));

        _asyncTransfer(owner(), MINT_TARTIST_PRICE);
        return newItemId;
    }

    function setRoyaltyRate(uint8 artistId, uint256 ratePerTarti) public {
        require(msg.sender == ownerOf(artistId), "norights");
        tartiRoyaltyRate[artistId] = ratePerTarti;
    }

    /**
    Mint a TARTI token.
    You cannot mint a TARTI token directly on the TARTI contract.
    You must do it through this (TARTIST) contract using the `newArt` function.
    Minter must send MINT_TARTI_PRICE + whatever royalty the TARTIST owner has set.
    */
    function newArt(uint8 artistId) public payable returns (uint256) {
        //address canot be blank
        require(_tartiAddr != address(0), "tarticontractnotset");

        //call newArt on the Tarti contract
        //Tarti only allows this contract to call that method
        //First check that the caller is allowed to use this tartist, either by owning it or paying royalties

        //norights = specified artist is not contractually obligated, nor even allowed, to make any art for you.
        if (tartiRoyaltyRate[artistId] == 0) {
            //if royalty rate is not set, then only the owner can make art with this Tartist
            require(msg.sender == ownerOf(artistId), "norights");
            require(msg.value == MINT_TARTI_PRICE, "missingcommission"); //.018 eth
        }
        if (tartiRoyaltyRate[artistId] > 0) {
            //if royalty rate is not set, then anyone can make art with this Tartist but they must pay the royalty.
            require(
                msg.value == MINT_TARTI_PRICE + tartiRoyaltyRate[artistId],
                "missingcommissionroyals"
            ); //.018 eth + royalty

            //mark the royalty as payable to Tartist owner (can be withdrawn using pull payment)
            _asyncTransfer(ownerOf(artistId), tartiRoyaltyRate[artistId]);
        }

        //use the Tarti contract to create a new Tarti token
        //Trait engine will see the new Tarti on the blockchain and create the art/music

        Tarti tarti = Tarti(_tartiAddr);

        //mint the tarti token
        uint256 newTartiToken = tarti.newArt(msg.sender, artistId);

        //mark payment payable to contract owner
        _asyncTransfer(owner(), MINT_TARTI_PRICE);
        return newTartiToken;
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

        bytes32 tokenUriBytesHash = keccak256(bytes(tokenURI(tokenId)));
        require(
            tokenUriBytesHash == keccak256(abi.encodePacked(_newMetadataUri)),
            "tartistnotnew"
        );

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

        bytes32 tokenUriBytesHash = keccak256(bytes(tokenURI(tokenId)));
        require(
            tokenUriBytesHash ==
                keccak256(abi.encodePacked(_inProcessMetadataUri)),
            "tartistnotstarted"
        );

        string memory newUri = string(abi.encodePacked(cid));
        _setTokenURI(tokenId, newUri);
        emit PermanentURI(newUri, tokenId);
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

    /// @dev Overridden in order to retrict caller to payee or owner
    function withdrawPayments(address payable payee) public virtual override {
        //Only allow payee to request withdrawl.
        //Help protect against gas forwarding attack.
        require(
            msg.sender == payee || msg.sender == owner(),
            "unauthwithdrawl"
        );
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

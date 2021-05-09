// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tarti.sol";

contract Tartist is ERC721URIStorage, IERC721Receiver, ReentrancyGuard, Ownable {

//what if we just hard code the arists, their traits, amd their birth dates.
//allowing themto be born dynamically.
//people will simply send eth this contract to buy their artist once it is available
//which we can just hard code.
//maybe allow bidding?

//ok for bidding, 
//start with some price and have it tick down
//first buyer at or above current price gets it
//no auction no queiinbg no bidding. Just bu yit now at current price or watch someone else get it.

//first one will be dj pudding as a POC. Proof is in the pudding.
//he will make mad beats but for a limited time. to try to prove that shit is dynamic
//in the white paper add that he birth wont occur if the artist isnt ready. 
//Actually and yeah have something in the coe that atcually checks the url and makes sure the artist is 
//actually alive and ready.
//so you cant get an artist that is bunk.
//and maybe an artist should even have one piece of art ready when they're first bought so buyer 
//doesnt need to wait? not sure about that though. 
//I mean what if an artist dies with no art though? Actually shiit that would make the artist mad valuable! 
//haha include that in the white paper.

//artists might die. Due to the cnetralied service failing. If they did they would likely all die together. 
//o their lifespan will be from their birth date giveing them different ages, 
//but they will all die on the same day if central service goes down. So liklihood of any artists having no art is very xlim.
//but no real risk if it happens, value wise, maybe

//ok im down with the hardocded artists if it doesnt cost too much money

    uint8 private _nextArtistId = 0;
    mapping (uint8 => bytes16) public traitChains;
    mapping (uint8 => uint16) public writersBlocks;
    mapping (uint8 => uint256) public artStartedTimes;
    mapping (uint8 => uint32) public birthdays;
    mapping (uint8 => uint32) public dateSigned;
    mapping (uint8 => uint256) public crPrices; //in milliether
    uint256[] private _allTokens;
    address private _tarti;

    constructor() ERC721("Tarti Artist", "TARTIST") {
        birthdays[0] = 0; //set to 0 for test should be: 1622505600; //Jun 01 2021 GMT DJ Pudding (Instrumental Music Producer)
        birthdays[1] = 1622678400; //set to 0 for test should be: 1622678400; Jun 03 2021 GMT DJ Deadeye Dick (Instrumental Music Producer)
        birthdays[2] = 1623715200; //Jun 15 2021 GMT Gemini Dank (Songwriter?)
        birthdays[3] = 1624579200; //Jun 25 2021 GMT So So Pica (Digital Painter (stills))
        birthdays[4] = 1625184000; //Jul 02 2021 GMT Jiff da Splef (Abstract Gif Production)
        birthdays[5] = 1628208000; //Aug 06 2021 GMT NameTbd (Abstract animated digital painting)
        birthdays[6] = 1630454400; //Sep 01 2021 GMT Bella Luisa (Instrumental and Vocal Music Production)
        birthdays[7] = 1634428800; //Oct 17 2021 GMT Dom tha Hustler (Beat boxer)
        birthdays[8] = 1640908800; //Dec 31 2021 GMT Precilla Saibyn (Digital Abstract Media Creator (dynamic paintings plus audio))
        birthdays[9] = 1640995200; //Jan 01 2022 GMT DJ .223 (Instrumental Music Producer)

        writersBlocks[0] = 10; //special case as Proof in Pudding. Allow every ten mins but kill artist young.
        writersBlocks[1] = 1440; //takes a full day DJ DED
        writersBlocks[2] = 1080; //takes a week, making his songs rarer, but slower gem dank
        writersBlocks[3] = 720;  //can do two paintings per day
        writersBlocks[4] = 360;  //can do four gifs per day
        writersBlocks[5] = 10;
        writersBlocks[6] = 0; //instant, on demand
        writersBlocks[7] = 0; //instant, on demand
        writersBlocks[8] = 2880; //one per every two days
        writersBlocks[9] = 2880; //one per every two days


        crPrices[0] = 100000000 gwei; //start at .1 eth
        crPrices[1] = 77 ether; //DJ DED
        crPrices[2] = 200 ether; //Gemini Dank
        crPrices[3] = 44 ether; //So So Pica
        crPrices[4] = 11 ether; //Jiff da Splef
        crPrices[5] = 55 ether; //Cents Amelia
        crPrices[6] = 0; //Not For Sale but anyone can make art (fee) and let peeople hear it eth Bella
        crPrices[7] = 0; //Not for Sale but anyone can make art (fee) and let people hear it eth Dom
        crPrices[8] = 300 ether; //300 eth Precilla Sybyn
        crPrices[9] = 223 ether; //223 eth DJ .223

        for (uint8 artistIdx = 0; artistIdx < 9; artistIdx++)
        {
            dateSigned[artistIdx] = 0;
        }

        //_deployArtContract();
    }

    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }

    /**
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) 
        external override pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721URIStorage) {
        return ERC721URIStorage._burn(tokenId);
    }

    //allows sending eth to this contract
    receive() external payable {}

    function getCurrentPrice(uint8 artistId)
    public view returns(uint256)
    {
        require(totalSupply() > artistId, "artist is not born yet");
        if (crPrices[artistId] == 0)
        {
            return 0;
        }
        uint256 subtractFromPrice = 0;
        
        //if the artist have never been signed
        //then their price goes down over time
        if ((dateSigned[artistId] == 0) && (block.timestamp > birthdays[artistId])) {
            subtractFromPrice = (block.timestamp - birthdays[artistId]) * 500000 wei;
        }

        //unsigned artists cant sell for less than 10000000 gwei (.01 eth)
        if (subtractFromPrice > (crPrices[artistId] - 10000000 gwei))
        {
            subtractFromPrice = (crPrices[artistId] > 10000000 gwei) ? crPrices[artistId] - 10000000 gwei : 0;
        }

        return (crPrices[artistId] - subtractFromPrice);
    }

    function buyRights(uint8 artistId)
    public payable nonReentrant {
        uint256 currentPrice = getCurrentPrice(artistId);
        uint256 neededGas; //@todo set based on current rates

        require(currentPrice != 0, "nosale"); //0 means it is not for sale
        require(msg.value >= currentPrice, "notenougheth");
        require(totalSupply() > artistId, "unbornartist");
        require(artistId < 10, "invalidartist");

        //mark it as priceless so no one else can buy it. 
        //if new owner wants to sell it they can change the price using setArtistCurrentPrice
        _setCurrentPrice(artistId, 0);

        //pay the owner (if not first signing, else pay the artist owner pay the artistartist)
        if (ownerOf(artistId) != address(this))
        {
            (bool ethSent, bytes memory sendEthData) = payable(ownerOf(artistId)).call{value: msg.value - neededGas}("");
            require (ethSent, "payunsignedfail");
        } else {
            (bool ethSent, bytes memory sendEthData) = payable(owner()).call{value: msg.value - neededGas}("");
            require (ethSent, "payownerfail");
        }

        //transfer ownership of the arist's copyrights to the new owner
        _transfer(ownerOf(artistId), msg.sender, artistId);

        //todo why were they using 256 bits for the timestamp? better doubl check maybe they use millisecs
        if (dateSigned[artistId] == 0)
        {
            dateSigned[artistId] = uint32(block.timestamp);
        }
    }


    //set price in wei
    function setArtistCurrentPrice(uint8 artistId, uint256 newPrice)
    public {
        require(msg.sender == ownerOf(artistId), "only owner can set price");

        if (newPrice < 10000000 gwei)
        {
            newPrice = 10000000 gwei;
        }    
        _setCurrentPrice(artistId, newPrice);
    }

    function _setCurrentPrice(uint8 artistId, uint256 newPrice)
    private {
        crPrices[artistId] = newPrice;
    }

//can tokend be the artist signature? (ie traits etc)
//this should happen automatically now if we have the artists precoded on blockchain
//this is ablockchain transaction that has a cost.
//I'd like this to happen automatically.
//questions:
//- how do automatically / event based on date?
//- how is it paid for? (money on the contract?)
//- how much will it cost?
    function newArtist(uint8 newArtistId, string memory ipfsId, bytes16 traitChain) 
    public nonReentrant onlyOwner {

//only certain people can mint artists
//would be dope to find a way to make it a bit open
//what needs to exist in the world for a bot?
//an entry in my bot database basically.
//but I dont want just anyone creating them willy nilly.
//people will just pass invalid garbage.
//i need to gebnerate a key from the trait db and use it as the seed
//and most guesses will be invalid seeds so they wont work
//and then make it so if they dont come from my wallet they have to pay my wallet
//if someone creates an artist token before it exists.. need to create aplaceholder
//that a client will interpret as "it is being born still"
//and lets lock that feature until I open it up

//at first I will create artists that Ive already setup
//but after the colony is unlicked this function will trigger tho automation of artist creation
//which is already implemented.
//just need it to be deployed reliably before having people depend on it.

        //make sure caller is sending the correct artist info
        require(newArtistId == _nextArtistId, "specified artist is wrong");

        //make sure its the arists bday (or after, just in case the caller is late)
        require(block.timestamp >= birthdays[newArtistId], "not their birthday");

        address ownerAddress = address(this);

        _nextArtistId++;
        _safeMint(ownerAddress, newArtistId);

        //ipfsId is used for the token url. When used with our base url
        //we will return our centralized version of it our our ipfs version of it
        //but same id can be used at pinata.
        _setTokenURI(newArtistId, ipfsId); //setter is part of Zeppelen contract. All it does is check that the token exists and then sets a value for a normal mapping

        //lets keep vital info on-chain

        //determines this artists style and abilities, sounds they choose, speeds, scales, 
        traitChains[newArtistId] = traitChain; 

        //number of minutes an artist must wait between generating art
        //for the first artist have the time be very short so we can prove its dynamic
        writersBlocks[newArtistId] = 100;

        //time last art was started.
        //this is used to calculate when the art is actually allowed to be minted
        artStartedTimes[newArtistId] = 0;

        _allTokens.push(newArtistId);

        //some data can go off-chain
        // artist name, birthdate, image urls, html url, etc
    }

    function newArt(uint8 artistId) payable nonReentrant public {

        //address canot be blank
        require(_tarti != address(0), "tartscontractnotset");
        require (msg.value >= 10000000 gwei, "must send commission"); //.01 eth

        //call newArt on the Tart contract
        //it will allow me since it only allows this contract to call that method
        //tell the new art method who the artist is

        //first check that the caller is the owber of the artist
        //if an artist has no owner, I forget who is allowed to use it? (maybe anyone but only if I get commissions)
        //thats a good idea. For ownerless i get commissions. for owned I dont

        //norights = specified artist is not contractually obligated, nor even allowed, to make any art for you.
        require (msg.sender == ownerOf(artistId), "norights");

        //make sure artist has had enought time since their last art generated
        require(block.timestamp >= artStartedTimes[artistId] + (writersBlocks[artistId] * 60), "too soon since last newArt");

        //use the art contract to create a new Tart token
        //Trait engine will see the new Art on the blockchain and create the art
        //the art package url will be based on the Tart tokenId
        //we will own the dns of whatever we use for IPFS so we can pre generate here and guarantee to have it      

        Tarti tarti = Tarti(_tarti);

        tarti.newArt(msg.sender, artistId, "someipfsurl");

        artStartedTimes[artistId] = block.timestamp;

        //original artistastist gets the commission
        //for now that is always the owner of the artist contract but we night change that
        (bool ethSent, bytes memory sendEthData) = payable(owner()).call{value: msg.value}("");
        require (ethSent, "could not pay the owner");
    } 

    // function _deployArtContract() internal {
    //     //presently thinking I want this contract to own the art contract.
    //     //thats the purpose of this function.
    //     //to be the original deployer of the art contract.
    //     //so this function would only ever get called on time in history.
    //     //there might be a better approach
    //     Tarti tart = new Tarti();
    //     _tarti = address(tarti);
    // }

    function setTartiAddr(address tartiAddr) public onlyOwner
    {
        _tarti = tartiAddr;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://tartscoin.com/tartst/";
    }
}
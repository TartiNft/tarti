const { expect } = require("chai");
const Tartist = artifacts.require('Tartist');
const Tarti = artifacts.require('Tarti');
const { BN, expectRevert } = require('@openzeppelin/test-helpers');

contract('Tartist', function(accounts) {
    this.artist = null;
    this.tart = null;
    const oneEth = web3.utils.toWei("1", "ether");

    beforeEach(async function() {
        if (this.artist == null)
        {
            this.artist = await Tartist.new();
            this.tart = await Tarti.new(this.artist.address);
            //await tart.transferOwnership(this.artist.address);
            await this.artist.setTartiAddr(this.tart.address);        
        }
    });


    it('newArtist will give birth to an artist', async function() {
        await this.artist.newArtist(0, web3.utils.fromAscii('abcdefghijklmnop'));
        expect(await this.artist.totalSupply()).to.be.bignumber.equal(new BN('1'));
    });

    it('test wallet will buy the artist rights', async function() {
        let startBal = web3.utils.toBN(await web3.eth.getBalance(accounts[0]));
        await this.artist.buyRights(0, { value: await this.artist.getCurrentPrice(0) });
        expect(await this.artist.dateSigned(0)).to.be.bignumber.greaterThan(new BN(0));
        expect(startBal).to.be.bignumber.greaterThan(web3.utils.toBN(await web3.eth.getBalance(accounts[0])));
    });

    it('artist owner can set current price', async function() {
        //we need to give away the artist in order to test buying it back
        //first lets set the price to something we know we can afford (for when we buy it back)
        await this.artist.setArtistCurrentPrice(0, new BN(oneEth));
        expect(await this.artist.getCurrentPrice(0)).to.be.bignumber.equal(new BN(oneEth));
    });

    it('test wallet will re-buy the artist rights after giving them away', async function() {
        //we need to give away the artist in order to test buying it back
        await this.artist.transferFrom(accounts[0], accounts[1], 0);
        expect( accounts[1] ).to.equal(await this.artist.ownerOf(0));

        await this.artist.buyRights(0, { value: await this.artist.getCurrentPrice(0) });
        expect( accounts[0] ).to.equal(await this.artist.ownerOf(0));
    });

    it('create new art', async function() {
        await expectRevert(this.artist.newArt(0), "must send commission");        

        await this.artist.newArt(0, { value: new BN(web3.utils.toWei("10000000", "gwei")) });
        expect( await this.artist.artStartedTimes(0) ).to.be.bignumber.greaterThan(new BN(0));

        //set price before transfer so that we can buy it back
        await this.artist.setArtistCurrentPrice(0, new BN(oneEth));

        //make sure non artist owner cannot make art with them
        await this.artist.transferFrom(accounts[0], accounts[1], 0);
        await expectRevert(this.artist.newArt(0, { value: new BN(web3.utils.toWei("10000000", "gwei")) }), "norights");
    });

    it('correct person gets paid when an artist rights is bought', async function() {
        //account 1 should currently own the artist.
        
        //account0 buys back artist
        let startBal = web3.utils.toBN(await web3.eth.getBalance(accounts[1]));
        await this.artist.buyRights(0, { value: await this.artist.getCurrentPrice(0) });
        expect( accounts[0] ).to.equal(await this.artist.ownerOf(0));

        //lets see if acct1 got paid proper like
        expect(startBal).to.be.bignumber.lessThan(web3.utils.toBN(await web3.eth.getBalance(accounts[1])));

    });

    it('ERC721 approve and transfer', async function() {
        //account 0 should currently own the artist.
        //make account 1 should  own the artist.
        await this.artist.transferFrom(accounts[0], accounts[1], 0);
        expect( accounts[1] ).to.equal(await this.artist.ownerOf(0));

        //call approve from account1 and give approve to acct0
        await this.artist.approve(accounts[0], 0, {from: accounts[1]});
        expect( accounts[0] ).to.equal(await this.artist.getApproved(0));

        //see if acct1 successfully granted acct0 the approve
        await this.artist.transferFrom(accounts[1], accounts[0], 0);

        expect( accounts[0] ).to.equal(await this.artist.ownerOf(0));
    });

    it('only i can set tart', async function() {
        await expectRevert(this.artist.setTartiAddr(this.tart.address, {from: accounts[1]}), "Ownable: caller is not the owner");
    });
    
});
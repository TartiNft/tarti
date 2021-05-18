const { expect } = require("chai");
const Tartist = artifacts.require('Tartist');
const Tarti = artifacts.require('Tarti');
const { BN, expectRevert } = require('@openzeppelin/test-helpers');

contract('Tarti', function(accounts) {
    
    it('newArt will not be allowed by non artist contract', async function() {
        const tartist = await Tartist.new();
        const tart = await Tarti.new(tartist.address);
        //await tart.transferOwnership(tartist.address);
        await expectRevert(tart.newArt(accounts[0], 0), "Ownable: caller is not the owner.");
    });

    it('create new art', async function() {
        const tartist = await Tartist.new();

        //setting this account as owner so can test newArt
        const tart = await Tarti.new(accounts[0]);

        await tartist.setTartiAddr(tart.address);        

        await tartist.newArtist(0, web3.utils.fromAscii('abcdefghijklmnop'));
        await tartist.buyRights(0, { value: await tartist.getCurrentPrice(0) });

        //lets make me the owner of the contract to test if it will work when called from the owner
        //although in relaity the tartst contract will always own the tarts contract

        await tart.newArt(accounts[0], 0);
        expect( await tartist.totalSupply() ).to.be.bignumber.greaterThan(new BN(0));

    });

    it('ERC721 approve and transfer', async function() {
        const tartist = await Tartist.new();
        const tart = await Tarti.new(tartist.address);
        await tartist.setTartiAddr(tart.address);        
        await tartist.newArtist(0, web3.utils.fromAscii('abcdefghijklmnop'));
        await tartist.buyRights(0, { value: await tartist.getCurrentPrice(0) });

        let commission = new BN(web3.utils.toWei("10000000", "gwei"))
        await tartist.newArt(0, {value: commission});

        //account 0 should currently own the art.
        //make account 1 own the art.
        await tart.transferFrom(accounts[0], accounts[1], 0);
        expect( accounts[1] ).to.equal(await tart.ownerOf(0));

        //call approve from account1 and give approve to acct0
        await tart.approve(accounts[0], 0, {from: accounts[1]});
        expect( accounts[0] ).to.equal(await tart.getApproved(0));

        //see if acct1 successfully granted acct0 the approve
        await tart.transferFrom(accounts[1], accounts[0], 0);
        expect( accounts[0] ).to.equal(await tart.ownerOf(0));
    });


});
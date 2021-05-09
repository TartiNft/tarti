module.exports = async function main(callback) {
    try {
        // const accounts = await web3.eth.getAccounts();
        // console.log(accounts);

        const Tarts = artifacts.require("TraitArtist");
        const tarts = await Tarts.deployed();
        
        value = await tarts.retrieve();
        console.log("tarts value is", value.toString());
        callback(0);
    } catch (error) {
        console.error(error);
        callback(1);
    }
}
const Tartist = artifacts.require("Tartist");
const Tarti = artifacts.require("Tarti");
module.exports = async function (deployer) {
    await deployer.deploy(Tartist);
    const tartistContract = await Tartist.deployed();

    await deployer.deploy(Tarti);
    const tartiContract = await Tarti.deployed();

    await tartistContract.setTartiAddr(tartiContract.address);
    await tartiContract.transferOwnership(tartistContract.address);
}
const Tartist = artifacts.require("Tartist");
const Tarti = artifacts.require("Tarti");
module.exports = async function (deployer) {
    await deployer.deploy(Tartist);
    const tartst = await Tartist.deployed();

    await deployer.deploy(Tarti);
    const tarts = await Tarti.deployed();

    await tartst.setTartiAddr(tarts.address);
}
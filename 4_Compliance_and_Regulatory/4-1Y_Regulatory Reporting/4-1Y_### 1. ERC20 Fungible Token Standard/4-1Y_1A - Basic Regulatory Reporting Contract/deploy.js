const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const name = "RegulatoryToken";
    const symbol = "REG";
    const BasicRegulatoryReporting = await hre.ethers.getContractFactory("BasicRegulatoryReporting");
    const contract = await BasicRegulatoryReporting.deploy(name, symbol);

    await contract.deployed();
    console.log("BasicRegulatoryReporting deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});

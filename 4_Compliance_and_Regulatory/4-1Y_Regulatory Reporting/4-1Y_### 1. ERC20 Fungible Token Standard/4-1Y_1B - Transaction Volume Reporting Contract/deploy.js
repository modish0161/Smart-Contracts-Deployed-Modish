const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const name = "VolumeToken";
    const symbol = "VOL";
    const TransactionVolumeReporting = await hre.ethers.getContractFactory("TransactionVolumeReporting");
    const contract = await TransactionVolumeReporting.deploy(name, symbol);

    await contract.deployed();
    console.log("TransactionVolumeReporting deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});

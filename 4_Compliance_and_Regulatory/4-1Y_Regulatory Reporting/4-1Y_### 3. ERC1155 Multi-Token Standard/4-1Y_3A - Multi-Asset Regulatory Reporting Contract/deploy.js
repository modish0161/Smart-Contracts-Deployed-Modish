const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const uri = "https://api.example.com/metadata/{id}.json"; // Base URI for the token metadata

    const Contract = await hre.ethers.getContractFactory("MultiAssetRegulatoryReporting");
    const contract = await Contract.deploy(uri);

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

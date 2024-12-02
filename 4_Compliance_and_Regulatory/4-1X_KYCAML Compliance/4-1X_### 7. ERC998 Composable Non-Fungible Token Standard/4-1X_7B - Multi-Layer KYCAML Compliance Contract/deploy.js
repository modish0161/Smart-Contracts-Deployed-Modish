const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const MultiLayerKYCAMLCompliance = await hre.ethers.getContractFactory("MultiLayerKYCAMLCompliance");
    const contract = await MultiLayerKYCAMLCompliance.deploy("Multi-Layer KYC/AML Compliance NFT", "MLKYC");

    await contract.deployed();
    console.log("MultiLayerKYCAMLCompliance deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});

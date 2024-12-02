const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const ComposableKYCAMLCompliance = await hre.ethers.getContractFactory("ComposableKYCAMLCompliance");
    const contract = await ComposableKYCAMLCompliance.deploy("Composable KYC/AML Compliance NFT", "cKYC");

    await contract.deployed();
    console.log("ComposableKYCAMLCompliance deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});

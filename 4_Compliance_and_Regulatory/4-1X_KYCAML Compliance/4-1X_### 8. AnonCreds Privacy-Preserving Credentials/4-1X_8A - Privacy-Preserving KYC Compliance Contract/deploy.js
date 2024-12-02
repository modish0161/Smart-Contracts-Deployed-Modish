const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const PrivacyPreservingKYCCompliance = await hre.ethers.getContractFactory("PrivacyPreservingKYCCompliance");
    const contract = await PrivacyPreservingKYCCompliance.deploy();

    await contract.deployed();
    console.log("PrivacyPreservingKYCCompliance deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});

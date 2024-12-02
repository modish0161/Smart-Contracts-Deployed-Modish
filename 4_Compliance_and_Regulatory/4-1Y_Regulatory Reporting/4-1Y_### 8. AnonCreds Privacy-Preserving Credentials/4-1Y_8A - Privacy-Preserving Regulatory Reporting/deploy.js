const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const PrivacyPreservingRegulatoryReporting = await hre.ethers.getContractFactory("PrivacyPreservingRegulatoryReporting");
    const authorityAddress = "0xYourAuthorityAddress"; // Replace with actual authority address

    const contract = await PrivacyPreservingRegulatoryReporting.deploy(authorityAddress);

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

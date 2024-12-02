const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const AnonymousSuspiciousActivityReporting = await hre.ethers.getContractFactory("AnonymousSuspiciousActivityReporting");
    const authorityAddress = "0xYourAuthorityAddress"; // Replace with actual authority address

    const contract = await AnonymousSuspiciousActivityReporting.deploy(authorityAddress);

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

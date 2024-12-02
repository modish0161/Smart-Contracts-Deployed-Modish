const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const SuspiciousActivityReporting = await hre.ethers.getContractFactory("SuspiciousActivityReporting");
    const contract = await SuspiciousActivityReporting.deploy(
        "Suspicious Activity Token",
        "SAT",
        hre.ethers.utils.parseUnits("1000", 18), // Initial threshold of 1000 tokens
        "0xYourAuthorityAddress" // Replace with actual authority address
    );

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

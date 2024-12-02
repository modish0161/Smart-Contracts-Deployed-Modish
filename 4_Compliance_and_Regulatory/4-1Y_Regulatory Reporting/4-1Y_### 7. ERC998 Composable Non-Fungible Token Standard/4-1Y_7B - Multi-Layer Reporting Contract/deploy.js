const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const MultiLayerReporting = await hre.ethers.getContractFactory("MultiLayerReporting");
    const authorityAddress = "0xYourAuthorityAddress"; // Replace with actual authority address
    const reportingThreshold = 10; // Example threshold

    const contract = await MultiLayerReporting.deploy(
        "Multi-Layer Token", // Token name
        "MLTKN", // Token symbol
        authorityAddress, // Authority address
        reportingThreshold // Reporting threshold
    );

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

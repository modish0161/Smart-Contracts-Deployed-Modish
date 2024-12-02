const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const ComposableTokenReporting = await hre.ethers.getContractFactory("ComposableTokenReporting");
    const authorityAddress = "0xYourAuthorityAddress"; // Replace with actual authority address
    const reportingThreshold = 10; // Example threshold of 10 child components

    const contract = await ComposableTokenReporting.deploy(
        "Composable Token", // Token name
        "COMPTKN", // Token symbol
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

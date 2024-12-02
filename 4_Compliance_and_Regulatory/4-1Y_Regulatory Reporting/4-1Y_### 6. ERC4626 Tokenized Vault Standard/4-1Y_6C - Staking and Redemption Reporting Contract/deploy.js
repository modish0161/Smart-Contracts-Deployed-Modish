const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const StakingRedemptionReporting = await hre.ethers.getContractFactory("StakingRedemptionReporting");
    const vaultToken = "0xYourERC20AssetAddress"; // Replace with the ERC20 asset address
    const authorityAddress = "0xYourAuthorityAddress"; // Replace with actual authority address
    const reportingThreshold = hre.ethers.utils.parseUnits("1000", 18); // Example threshold of 1,000 tokens

    const contract = await StakingRedemptionReporting.deploy(
        vaultToken, // ERC20 asset
        "Vault Token", // Vault name
        "VT", // Vault symbol
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

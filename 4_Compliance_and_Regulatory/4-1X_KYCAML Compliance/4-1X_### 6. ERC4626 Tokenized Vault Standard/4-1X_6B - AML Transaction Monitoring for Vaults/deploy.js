const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const ComplianceOfficer = deployer.address; // For demo purposes
    const largeDepositThreshold = hre.ethers.utils.parseEther("1000"); // Example threshold
    const largeWithdrawalThreshold = hre.ethers.utils.parseEther("1000"); // Example threshold

    const AMLTransactionMonitoringVault = await hre.ethers.getContractFactory("AMLTransactionMonitoringVault");
    const assetAddress = "[ERC20_TOKEN_ADDRESS]"; // Replace with the ERC20 token address used as the vault asset
    const contract = await AMLTransactionMonitoringVault.deploy(
        assetAddress,
        "AML Transaction Monitoring Vault",
        "vAML",
        ComplianceOfficer,
        largeDepositThreshold,
        largeWithdrawalThreshold
    );

    await contract.deployed();
    console.log("AMLTransactionMonitoringVault deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});

const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const ComplianceOfficer = deployer.address; // For demo purposes
    const rewardRate = hre.ethers.utils.parseUnits("0.1", 18); // Example reward rate

    const StakingAndYieldComplianceVault = await hre.ethers.getContractFactory("StakingAndYieldComplianceVault");
    const assetAddress = "[ERC20_TOKEN_ADDRESS]"; // Replace with the ERC20 token address used as the vault asset
    const contract = await StakingAndYieldComplianceVault.deploy(
        assetAddress,
        "Staking and Yield Compliance Vault",
        "sYCV",
        ComplianceOfficer,
        rewardRate
    );

    await contract.deployed();
    console.log("StakingAndYieldComplianceVault deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});

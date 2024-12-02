const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const ComplianceOfficer = deployer.address; // For demo purposes

    const VaultKYCAMLCompliance = await hre.ethers.getContractFactory("VaultKYCAMLCompliance");
    const assetAddress = "[ERC20_TOKEN_ADDRESS]"; // Replace with the ERC20 token address used as the vault asset
    const contract = await VaultKYCAMLCompliance.deploy(assetAddress, "Vault KYC/AML Compliance", "vKYC", ComplianceOfficer);

    await contract.deployed();
    console.log("VaultKYCAMLCompliance deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});

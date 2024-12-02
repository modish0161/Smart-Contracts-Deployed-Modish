const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const VaultTaxComplianceContract = await hre.ethers.getContractFactory("VaultTaxComplianceContract");
    const assetAddress = "0xAssetTokenAddress"; // Replace with the actual ERC20 token address used as asset in the vault
    const initialTaxAuthority = "0xTaxAuthorityAddress"; // Replace with the actual tax authority address
    const profitTaxRate = 500; // Set initial profit tax rate (in basis points)
    const yieldTaxRate = 300; // Set initial yield tax rate (in basis points)

    const contract = await VaultTaxComplianceContract.deploy(
        assetAddress,
        "VaultToken", // Name of the vault token
        "VTK", // Symbol of the vault token
        profitTaxRate,
        yieldTaxRate,
        initialTaxAuthority
    );

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

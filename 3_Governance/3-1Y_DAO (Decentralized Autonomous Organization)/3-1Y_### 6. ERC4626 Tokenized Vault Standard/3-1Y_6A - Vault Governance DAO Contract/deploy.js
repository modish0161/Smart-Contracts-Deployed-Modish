// scripts/deploy.js

async function main() {
    // Get the contract factory
    const VaultGovernanceDAO = await ethers.getContractFactory("VaultGovernanceDAO");
  
    // Deployment parameters
    const assetAddress = "0xYourAssetAddress"; // Replace with the tokenized asset address
    const vaultName = "Vault Governance DAO";
    const vaultSymbol = "VGDAO";
    const governanceTokenAddress = "0xYourGovernanceTokenAddress"; // Replace with the governance token address
    const votingDuration = 7 * 24 * 60 * 60; // 7 days
  
    // Deploy the contract with necessary parameters
    const vaultGovernanceDAO = await VaultGovernanceDAO.deploy(
      assetAddress, vaultName, vaultSymbol, governanceTokenAddress, votingDuration
    );
  
    await vaultGovernanceDAO.deployed();
  
    console.log("VaultGovernanceDAO deployed to:", vaultGovernanceDAO.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
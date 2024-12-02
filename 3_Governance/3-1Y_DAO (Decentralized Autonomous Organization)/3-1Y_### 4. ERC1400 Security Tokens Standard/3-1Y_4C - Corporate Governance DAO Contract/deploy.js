// scripts/deploy.js

async function main() {
    // Get the contract factory
    const CorporateGovernanceDAO = await ethers.getContractFactory("CorporateGovernanceDAO");
  
    // Deployment parameters
    const name = "CorporateSecurityToken";
    const symbol = "CST";
    const decimals = 18;
    const controllers = []; // Add controllers' addresses if needed
    const defaultPartitions = [ethers.utils.formatBytes32String("partition1")];
  
    // Deploy the contract with necessary parameters
    const corporateGovernanceDAO = await CorporateGovernanceDAO.deploy(
      name, symbol, decimals, controllers, defaultPartitions
    );
  
    await corporateGovernanceDAO.deployed();
  
    console.log("CorporateGovernanceDAO deployed to:", corporateGovernanceDAO.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
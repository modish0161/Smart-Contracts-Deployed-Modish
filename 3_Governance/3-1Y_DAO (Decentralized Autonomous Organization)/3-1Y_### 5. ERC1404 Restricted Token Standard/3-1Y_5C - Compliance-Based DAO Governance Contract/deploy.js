// scripts/deploy.js

async function main() {
    // Get the contract factory
    const ComplianceBasedDAO = await ethers.getContractFactory("ComplianceBasedDAO");
  
    // Deployment parameters
    const complianceTokenAddress = "0xYourComplianceTokenAddress"; // Replace with the ERC1404 token address
    const votingDuration = 7 * 24 * 60 * 60; // 7 days
    const priceFeedAddress = "0xYourChainlinkPriceFeedAddress"; // Replace with the Chainlink price feed address
  
    // Deploy the contract with necessary parameters
    const complianceBasedDAO = await ComplianceBasedDAO.deploy(
      complianceTokenAddress, votingDuration, priceFeedAddress
    );
  
    await complianceBasedDAO.deployed();
  
    console.log("ComplianceBasedDAO deployed to:", complianceBasedDAO.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
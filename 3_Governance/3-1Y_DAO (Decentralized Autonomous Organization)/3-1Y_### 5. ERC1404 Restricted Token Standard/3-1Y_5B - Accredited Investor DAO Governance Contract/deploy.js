// scripts/deploy.js

async function main() {
    // Get the contract factory
    const AccreditedInvestorDAO = await ethers.getContractFactory("AccreditedInvestorDAO");
  
    // Deployment parameters
    const accreditedTokenAddress = "0xYourAccreditedTokenAddress"; // Replace with the ERC1404 token address
    const votingDuration = 7 * 24 * 60 * 60; // 7 days
  
    // Deploy the contract with necessary parameters
    const accreditedInvestorDAO = await AccreditedInvestorDAO.deploy(
      accreditedTokenAddress, votingDuration
    );
  
    await accreditedInvestorDAO.deployed();
  
    console.log("AccreditedInvestorDAO deployed to:", accreditedInvestorDAO.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
// scripts/deploy.js

async function main() {
    // Get the contract factory
    const ComposableTokenDAOGovernance = await ethers.getContractFactory("ComposableTokenDAOGovernance");
  
    // Deployment parameters
    const governanceTokenAddress = "0xYourGovernanceTokenAddress"; // Replace with the governance token address
    const name = "Composable Token DAO Governance";
    const symbol = "CTDG";
    const votingDuration = 7 * 24 * 60 * 60; // 7 days
    const minimumTokenThreshold = 1; // Replace with desired minimum token threshold
  
    // Deploy the contract with necessary parameters
    const composableTokenDAOGovernance = await ComposableTokenDAOGovernance.deploy(
      name, symbol, governanceTokenAddress, votingDuration, minimumTokenThreshold
    );
  
    await composableTokenDAOGovernance.deployed();
  
    console.log("ComposableTokenDAOGovernance deployed to:", composableTokenDAOGovernance.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
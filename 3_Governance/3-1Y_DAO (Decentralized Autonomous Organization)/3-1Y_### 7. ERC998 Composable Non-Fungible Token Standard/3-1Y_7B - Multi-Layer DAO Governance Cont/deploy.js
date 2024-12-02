// scripts/deploy.js

async function main() {
    // Get the contract factory
    const MultiLayerDAOGovernance = await ethers.getContractFactory("MultiLayerDAOGovernance");
  
    // Deployment parameters
    const governanceTokenAddress = "0xYourGovernanceTokenAddress"; // Replace with the governance token address
    const name = "Multi-Layer DAO Governance";
    const symbol = "MLDG";
    const votingDuration = 7 * 24 * 60 * 60; // 7 days
    const minimumTokenThreshold = 1; // Replace with desired minimum token threshold
  
    // Deploy the contract with necessary parameters
    const multiLayerDAOGovernance = await MultiLayerDAOGovernance.deploy(
      name, symbol, governanceTokenAddress, votingDuration, minimumTokenThreshold
    );
  
    await multiLayerDAOGovernance.deployed();
  
    console.log("MultiLayerDAOGovernance deployed to:", multiLayerDAOGovernance.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
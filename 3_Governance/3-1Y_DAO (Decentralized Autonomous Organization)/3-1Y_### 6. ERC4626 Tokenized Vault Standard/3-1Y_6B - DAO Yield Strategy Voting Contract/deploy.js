// scripts/deploy.js

async function main() {
    // Get the contract factory
    const DAOYieldStrategyVoting = await ethers.getContractFactory("DAOYieldStrategyVoting");
  
    // Deployment parameters
    const assetAddress = "0xYourAssetAddress"; // Replace with the tokenized asset address
    const vaultName = "DAO Yield Strategy Voting";
    const vaultSymbol = "DYSV";
    const governanceTokenAddress = "0xYourGovernanceTokenAddress"; // Replace with the governance token address
    const votingDuration = 7 * 24 * 60 * 60; // 7 days
  
    // Deploy the contract with necessary parameters
    const daoYieldStrategyVoting = await DAOYieldStrategyVoting.deploy(
      assetAddress, vaultName, vaultSymbol, governanceTokenAddress, votingDuration
    );
  
    await daoYieldStrategyVoting.deployed();
  
    console.log("DAOYieldStrategyVoting deployed to:", daoYieldStrategyVoting.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
// scripts/deploy.js

async function main() {
    // Get the contract factory
    const DAOVotingRegulatedAssets = await ethers.getContractFactory("DAOVotingRegulatedAssets");
  
    // Deployment parameters
    const name = "SecurityTokenDAO";
    const symbol = "STDAO";
    const decimals = 18;
    const controllers = []; // Add controllers' addresses if needed
    const defaultPartitions = [ethers.utils.formatBytes32String("partition1")];
  
    // Deploy the contract with necessary parameters
    const daoVotingRegulatedAssets = await DAOVotingRegulatedAssets.deploy(
      name, symbol, decimals, controllers, defaultPartitions
    );
  
    await daoVotingRegulatedAssets.deployed();
  
    console.log("DAOVotingRegulatedAssets deployed to:", daoVotingRegulatedAssets.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
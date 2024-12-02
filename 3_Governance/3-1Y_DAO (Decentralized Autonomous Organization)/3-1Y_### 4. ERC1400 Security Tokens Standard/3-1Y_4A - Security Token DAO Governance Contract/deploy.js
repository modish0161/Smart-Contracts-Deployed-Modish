// scripts/deploy.js

async function main() {
    // Get the contract factory
    const SecurityTokenDAOGovernance = await ethers.getContractFactory("SecurityTokenDAOGovernance");
  
    // Deployment parameters
    const name = "SecurityTokenDAO";
    const symbol = "STDAO";
    const decimals = 18;
    const controllers = []; // Add controllers' addresses if needed
    const defaultPartitions = [ethers.utils.formatBytes32String("partition1")];
  
    // Deploy the contract with necessary parameters
    const securityTokenDAOGovernance = await SecurityTokenDAOGovernance.deploy(name, symbol, decimals, controllers, defaultPartitions);
  
    await securityTokenDAOGovernance.deployed();
  
    console.log("SecurityTokenDAOGovernance deployed to:", securityTokenDAOGovernance.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
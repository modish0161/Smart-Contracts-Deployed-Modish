// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const defaultOperators = []; // List of default operators, if any
  
    const RealTimePortfolioOptimization = await ethers.getContractFactory("RealTimePortfolioOptimization");
    const contract = await RealTimePortfolioOptimization.deploy("Real-Time Portfolio Token", "RTPT", defaultOperators);
  
    console.log("RealTimePortfolioOptimization deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
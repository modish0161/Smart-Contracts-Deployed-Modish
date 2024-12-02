// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const ComposablePortfolioManagement = await ethers.getContractFactory("ComposablePortfolioManagement");
    const contract = await ComposablePortfolioManagement.deploy();
  
    console.log("ComposablePortfolioManagement deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
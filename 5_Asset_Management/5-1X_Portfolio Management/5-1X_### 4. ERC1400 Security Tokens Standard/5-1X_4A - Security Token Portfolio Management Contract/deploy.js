// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const SecurityTokenPortfolioManagement = await ethers.getContractFactory("SecurityTokenPortfolioManagement");
    const contract = await SecurityTokenPortfolioManagement.deploy();
  
    console.log("SecurityTokenPortfolioManagement deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
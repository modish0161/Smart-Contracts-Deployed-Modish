// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const RestrictedTokenPortfolioManagement = await ethers.getContractFactory("RestrictedTokenPortfolioManagement");
    const contract = await RestrictedTokenPortfolioManagement.deploy();
  
    console.log("RestrictedTokenPortfolioManagement deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
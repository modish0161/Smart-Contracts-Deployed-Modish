// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const AccreditedInvestorPortfolioRebalancing = await ethers.getContractFactory("AccreditedInvestorPortfolioRebalancing");
    const contract = await AccreditedInvestorPortfolioRebalancing.deploy();
  
    console.log("AccreditedInvestorPortfolioRebalancing deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
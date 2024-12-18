// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const ComplianceDrivenPortfolioAdjustment = await ethers.getContractFactory("ComplianceDrivenPortfolioAdjustment");
    const contract = await ComplianceDrivenPortfolioAdjustment.deploy();
  
    console.log("ComplianceDrivenPortfolioAdjustment deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
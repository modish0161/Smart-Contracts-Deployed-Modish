// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const profitToken = "0x123..."; // Replace with actual profit token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const AccreditedInvestorReinvestmentWithPrivacy = await ethers.getContractFactory("AccreditedInvestorReinvestmentWithPrivacy");
    const contract = await AccreditedInvestorReinvestmentWithPrivacy.deploy(profitToken);
  
    console.log("AccreditedInvestorReinvestmentWithPrivacy deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const securityTokenAddress = "0x123..."; // Replace with actual security token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const DividendReinvestmentSecurityToken = await ethers.getContractFactory("DividendReinvestmentSecurityToken");
    const contract = await DividendReinvestmentSecurityToken.deploy(securityTokenAddress);
  
    console.log("DividendReinvestmentSecurityToken deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
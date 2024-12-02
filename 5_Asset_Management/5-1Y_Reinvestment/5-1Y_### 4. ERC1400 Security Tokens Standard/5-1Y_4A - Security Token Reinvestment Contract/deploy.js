// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const securityTokenAddress = "0x123..."; // Replace with actual security token address
    const performanceOracleAddress = "0x456..."; // Replace with actual oracle address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const SecurityTokenReinvestmentContract = await ethers.getContractFactory("SecurityTokenReinvestmentContract");
    const contract = await SecurityTokenReinvestmentContract.deploy(securityTokenAddress, performanceOracleAddress);
  
    console.log("SecurityTokenReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
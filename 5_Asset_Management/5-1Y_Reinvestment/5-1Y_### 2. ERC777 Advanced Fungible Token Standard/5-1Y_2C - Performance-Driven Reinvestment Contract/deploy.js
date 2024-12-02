// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const profitTokenAddress = "0x123..."; // Replace with actual profit token address
    const performanceOracleAddress = "0x456..."; // Replace with actual oracle address
    const performanceThreshold = 100; // Initial threshold value
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PerformanceDrivenReinvestmentContract = await ethers.getContractFactory("PerformanceDrivenReinvestmentContract");
    const contract = await PerformanceDrivenReinvestmentContract.deploy(profitTokenAddress, performanceOracleAddress, performanceThreshold);
  
    console.log("PerformanceDrivenReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
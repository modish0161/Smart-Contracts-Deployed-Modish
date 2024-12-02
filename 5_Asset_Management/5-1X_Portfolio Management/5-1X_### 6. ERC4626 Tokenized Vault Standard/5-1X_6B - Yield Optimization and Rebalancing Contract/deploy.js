// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const YieldOptimizationAndRebalancing = await ethers.getContractFactory("YieldOptimizationAndRebalancing");
    const contract = await YieldOptimizationAndRebalancing.deploy("0xAssetTokenAddress", 100, "0xOracleAddress");
  
    console.log("YieldOptimizationAndRebalancing deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const profitTokenAddress = "0x123..."; // Replace with actual profit token address
    const performanceOracleAddress = "0x456..."; // Replace with actual oracle address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const MultiAssetReinvestmentContract = await ethers.getContractFactory("MultiAssetReinvestmentContract");
    const contract = await MultiAssetReinvestmentContract.deploy(profitTokenAddress, performanceOracleAddress);
  
    console.log("MultiAssetReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
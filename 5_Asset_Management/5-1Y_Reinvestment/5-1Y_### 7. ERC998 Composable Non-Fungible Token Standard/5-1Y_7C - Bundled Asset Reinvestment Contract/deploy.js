// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const profitToken = "0x123..."; // Replace with actual profit token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const BundledAssetReinvestmentContract = await ethers.getContractFactory("BundledAssetReinvestmentContract");
    const contract = await BundledAssetReinvestmentContract.deploy("Bundled Asset Reinvestment", "BAR", profitToken);
  
    console.log("BundledAssetReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
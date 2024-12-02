// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const vaultAddress = "0x123..."; // Replace with actual vault address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PooledAssetReinvestmentContract = await ethers.getContractFactory("PooledAssetReinvestmentContract");
    const contract = await PooledAssetReinvestmentContract.deploy(vaultAddress);
  
    console.log("PooledAssetReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
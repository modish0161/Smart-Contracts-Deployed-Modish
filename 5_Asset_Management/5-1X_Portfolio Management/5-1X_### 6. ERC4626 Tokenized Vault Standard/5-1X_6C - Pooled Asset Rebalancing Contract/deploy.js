// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PooledAssetRebalancing = await ethers.getContractFactory("PooledAssetRebalancing");
    const contract = await PooledAssetRebalancing.deploy("0xAssetTokenAddress", 100);
  
    console.log("PooledAssetRebalancing deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
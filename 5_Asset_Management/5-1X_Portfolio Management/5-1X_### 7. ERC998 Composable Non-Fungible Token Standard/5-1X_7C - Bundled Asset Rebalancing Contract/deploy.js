// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const BundledAssetRebalancing = await ethers.getContractFactory("BundledAssetRebalancing");
    const contract = await BundledAssetRebalancing.deploy();
  
    console.log("BundledAssetRebalancing deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
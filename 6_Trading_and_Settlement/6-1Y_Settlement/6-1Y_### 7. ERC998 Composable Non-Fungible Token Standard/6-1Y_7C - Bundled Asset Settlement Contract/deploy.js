async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const BundledAssetSettlement = await ethers.getContractFactory("BundledAssetSettlement");
    const bundledAssetSettlement = await BundledAssetSettlement.deploy("Bundled Asset Settlement Token", "BAST");
  
    console.log("BundledAssetSettlement deployed to:", bundledAssetSettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  
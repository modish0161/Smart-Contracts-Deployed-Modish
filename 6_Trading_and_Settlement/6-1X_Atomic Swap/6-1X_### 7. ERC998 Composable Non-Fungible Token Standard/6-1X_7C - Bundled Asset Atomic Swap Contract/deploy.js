async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const BundledAssetAtomicSwap = await ethers.getContractFactory("BundledAssetAtomicSwap");
    const bundledAssetAtomicSwap = await BundledAssetAtomicSwap.deploy();
  
    console.log("BundledAssetAtomicSwap deployed to:", bundledAssetAtomicSwap.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  
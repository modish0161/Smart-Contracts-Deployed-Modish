async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PooledAssetAtomicSwap = await ethers.getContractFactory("PooledAssetAtomicSwap");
    const pooledAssetAtomicSwap = await PooledAssetAtomicSwap.deploy();
  
    console.log("PooledAssetAtomicSwap deployed to:", pooledAssetAtomicSwap.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  
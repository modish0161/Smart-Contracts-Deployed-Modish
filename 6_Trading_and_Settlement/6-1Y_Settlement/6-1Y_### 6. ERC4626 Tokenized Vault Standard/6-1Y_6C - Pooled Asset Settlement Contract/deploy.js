async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const VaultTokenAddress = "0xYourVaultTokenAddress"; // Replace with your ERC4626 token address
  
    const PooledAssetSettlement = await ethers.getContractFactory("PooledAssetSettlement");
    const pooledAssetSettlement = await PooledAssetSettlement.deploy(VaultTokenAddress);
  
    console.log("PooledAssetSettlement deployed to:", pooledAssetSettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  
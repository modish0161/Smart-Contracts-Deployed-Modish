async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const vaultTokenAddress = "0xYourVaultTokenAddress"; // Replace with actual ERC4626 vault token contract address
  
    const PooledAssetEscrowContract = await ethers.getContractFactory("PooledAssetEscrowContract");
    const escrow = await PooledAssetEscrowContract.deploy(vaultTokenAddress);
    console.log("PooledAssetEscrowContract deployed to:", escrow.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
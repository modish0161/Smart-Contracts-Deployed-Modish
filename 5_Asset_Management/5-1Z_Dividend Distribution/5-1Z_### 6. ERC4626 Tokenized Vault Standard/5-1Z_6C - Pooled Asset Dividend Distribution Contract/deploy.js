// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const vaultToken = "0xYourERC4626VaultTokenAddress"; // Replace with actual ERC4626 vault token address
    const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 dividend token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PooledAssetDividendDistribution = await ethers.getContractFactory("PooledAssetDividendDistribution");
    const contract = await PooledAssetDividendDistribution.deploy(
      vaultToken,
      dividendToken
    );
  
    console.log("PooledAssetDividendDistribution deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
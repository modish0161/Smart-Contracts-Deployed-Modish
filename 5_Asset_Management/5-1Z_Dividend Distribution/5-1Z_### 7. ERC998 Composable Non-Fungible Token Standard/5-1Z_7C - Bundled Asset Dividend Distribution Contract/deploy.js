// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const composableToken = "0xYourERC998ComposableTokenAddress"; // Replace with actual ERC998 composable token address
    const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 dividend token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const BundledAssetDividendDistribution = await ethers.getContractFactory("BundledAssetDividendDistribution");
    const contract = await BundledAssetDividendDistribution.deploy(
      composableToken,
      dividendToken
    );
  
    console.log("BundledAssetDividendDistribution deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
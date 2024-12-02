// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const assetToken = "0xYourERC1155TokenAddress"; // Replace with actual ERC1155 token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const MultiAssetDividendDistribution = await ethers.getContractFactory("MultiAssetDividendDistribution");
    const contract = await MultiAssetDividendDistribution.deploy(assetToken);
  
    console.log("MultiAssetDividendDistribution deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const assetToken = "0xYourERC1155TokenAddress"; // Replace with actual ERC1155 token address
    const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const BatchDividendDistribution = await ethers.getContractFactory("BatchDividendDistribution");
    const contract = await BatchDividendDistribution.deploy(assetToken, dividendToken);
  
    console.log("BatchDividendDistribution deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
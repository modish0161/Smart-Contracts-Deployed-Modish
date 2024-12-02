// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const profitToken = "0x123..."; // Replace with actual profit token address
    const assetToken = "0x456..."; // Replace with actual asset token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const ComposableTokenReinvestmentContract = await ethers.getContractFactory("ComposableTokenReinvestmentContract");
    const contract = await ComposableTokenReinvestmentContract.deploy("Composable Token Reinvestment", "CTR", profitToken, assetToken);
  
    console.log("ComposableTokenReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
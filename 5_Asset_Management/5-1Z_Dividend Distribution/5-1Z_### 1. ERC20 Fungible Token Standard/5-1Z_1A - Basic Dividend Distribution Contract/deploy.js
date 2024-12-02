// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const dividendToken = "0xYourDividendTokenAddress"; // Replace with actual dividend token address
    const rewardToken = "0xYourRewardTokenAddress"; // Replace with actual reward token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const BasicDividendDistributionContract = await ethers.getContractFactory("BasicDividendDistributionContract");
    const contract = await BasicDividendDistributionContract.deploy(dividendToken, rewardToken);
  
    console.log("BasicDividendDistributionContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
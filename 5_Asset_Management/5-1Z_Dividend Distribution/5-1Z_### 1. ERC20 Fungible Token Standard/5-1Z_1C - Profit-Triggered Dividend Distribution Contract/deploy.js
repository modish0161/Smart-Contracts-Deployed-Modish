// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const dividendToken = "0xYourDividendTokenAddress"; // Replace with actual dividend token address
    const profitThreshold = ethers.utils.parseUnits("1000", 18); // Set a threshold value
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const ProfitTriggeredDividendDistributionContract = await ethers.getContractFactory("ProfitTriggeredDividendDistributionContract");
    const contract = await ProfitTriggeredDividendDistributionContract.deploy(dividendToken, profitThreshold);
  
    console.log("ProfitTriggeredDividendDistributionContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
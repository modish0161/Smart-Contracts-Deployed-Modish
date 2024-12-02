// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const dividendToken = "0xYourDividendTokenAddress"; // Replace with actual dividend token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PercentageBasedDividendDistributionContract = await ethers.getContractFactory("PercentageBasedDividendDistributionContract");
    const contract = await PercentageBasedDividendDistributionContract.deploy(dividendToken);
  
    console.log("PercentageBasedDividendDistributionContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
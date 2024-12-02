// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const dividendToken = "0xYourDividendTokenAddress"; // Replace with actual dividend token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const RealTimeDividendDistribution = await ethers.getContractFactory("RealTimeDividendDistribution");
    const contract = await RealTimeDividendDistribution.deploy(dividendToken);
  
    console.log("RealTimeDividendDistribution deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const dividendToken = "0xYourDividendTokenAddress"; // Replace with actual dividend token address
    const operators = ["0xOperatorAddress1", "0xOperatorAddress2"]; // Replace with actual operator addresses
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const AdvancedDividendDistributionContract = await ethers.getContractFactory("AdvancedDividendDistributionContract");
    const contract = await AdvancedDividendDistributionContract.deploy(dividendToken, operators);
  
    console.log("AdvancedDividendDistributionContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const investmentTokenAddress = "0x123..."; // Replace with actual investment token address
    const performanceOracleAddress = "0x456..."; // Replace with actual oracle address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const BatchReinvestmentContract = await ethers.getContractFactory("BatchReinvestmentContract");
    const contract = await BatchReinvestmentContract.deploy(investmentTokenAddress, performanceOracleAddress);
  
    console.log("BatchReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
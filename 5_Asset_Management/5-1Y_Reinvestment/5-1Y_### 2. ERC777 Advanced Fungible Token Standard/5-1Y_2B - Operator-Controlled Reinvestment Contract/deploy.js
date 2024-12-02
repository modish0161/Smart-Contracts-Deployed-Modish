// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const dividendTokenAddress = "0x123..."; // Replace with actual dividend token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const OperatorControlledReinvestmentContract = await ethers.getContractFactory("OperatorControlledReinvestmentContract");
    const contract = await OperatorControlledReinvestmentContract.deploy(dividendTokenAddress);
  
    console.log("OperatorControlledReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
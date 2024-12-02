// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const profitToken = "0x123..."; // Replace with actual profit token address
    const reinvestToken = "0x456..."; // Replace with actual reinvestment token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const MultiLayerReinvestmentContract = await ethers.getContractFactory("MultiLayerReinvestmentContract");
    const contract = await MultiLayerReinvestmentContract.deploy("Multi Layer Reinvestment", "MLR", profitToken, reinvestToken);
  
    console.log("MultiLayerReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
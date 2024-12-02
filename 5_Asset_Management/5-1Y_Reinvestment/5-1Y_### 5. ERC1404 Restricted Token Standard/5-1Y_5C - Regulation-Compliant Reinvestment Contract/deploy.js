// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const restrictedTokenAddress = "0x123..."; // Replace with actual restricted token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const RegulationCompliantReinvestmentContract = await ethers.getContractFactory("RegulationCompliantReinvestmentContract");
    const contract = await RegulationCompliantReinvestmentContract.deploy(restrictedTokenAddress);
  
    console.log("RegulationCompliantReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
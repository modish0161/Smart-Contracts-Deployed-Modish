// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const restrictedTokenAddress = "0x123..."; // Replace with actual restricted token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const AccreditedInvestorReinvestmentContract = await ethers.getContractFactory("AccreditedInvestorReinvestmentContract");
    const contract = await AccreditedInvestorReinvestmentContract.deploy(restrictedTokenAddress);
  
    console.log("AccreditedInvestorReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
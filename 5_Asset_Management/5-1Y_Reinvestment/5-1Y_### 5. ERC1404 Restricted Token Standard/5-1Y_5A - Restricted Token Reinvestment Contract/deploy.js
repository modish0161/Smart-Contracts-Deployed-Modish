// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const restrictedTokenAddress = "0x123..."; // Replace with actual restricted token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const RestrictedTokenReinvestmentContract = await ethers.getContractFactory("RestrictedTokenReinvestmentContract");
    const contract = await RestrictedTokenReinvestmentContract.deploy(restrictedTokenAddress);
  
    console.log("RestrictedTokenReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
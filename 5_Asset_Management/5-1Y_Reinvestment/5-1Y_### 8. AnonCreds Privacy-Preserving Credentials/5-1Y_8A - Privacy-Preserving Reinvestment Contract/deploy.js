// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const profitToken = "0x123..."; // Replace with actual profit token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PrivacyPreservingReinvestmentContract = await ethers.getContractFactory("PrivacyPreservingReinvestmentContract");
    const contract = await PrivacyPreservingReinvestmentContract.deploy(profitToken);
  
    console.log("PrivacyPreservingReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
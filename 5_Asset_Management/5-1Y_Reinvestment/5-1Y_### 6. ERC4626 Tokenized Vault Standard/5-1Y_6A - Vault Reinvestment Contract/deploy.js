// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const vaultAddress = "0x123..."; // Replace with actual vault address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const VaultReinvestmentContract = await ethers.getContractFactory("VaultReinvestmentContract");
    const contract = await VaultReinvestmentContract.deploy(vaultAddress);
  
    console.log("VaultReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
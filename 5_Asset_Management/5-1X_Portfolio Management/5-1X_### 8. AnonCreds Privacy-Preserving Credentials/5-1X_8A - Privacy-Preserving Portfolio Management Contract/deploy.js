// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const initialMerkleRoot = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"; // Replace with actual Merkle root
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PrivacyPreservingPortfolioManagement = await ethers.getContractFactory("PrivacyPreservingPortfolioManagement");
    const contract = await PrivacyPreservingPortfolioManagement.deploy(initialMerkleRoot);
  
    console.log("PrivacyPreservingPortfolioManagement deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
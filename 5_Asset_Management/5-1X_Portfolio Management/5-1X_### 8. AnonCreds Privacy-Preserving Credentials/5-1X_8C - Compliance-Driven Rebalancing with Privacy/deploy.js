// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const initialMerkleRoot = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"; // Replace with actual Merkle root
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const ComplianceDrivenRebalancingWithPrivacy = await ethers.getContractFactory("ComplianceDrivenRebalancingWithPrivacy");
    const contract = await ComplianceDrivenRebalancingWithPrivacy.deploy(initialMerkleRoot);
  
    console.log("ComplianceDrivenRebalancingWithPrivacy deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const ComplianceDrivenRebalancing = await ethers.getContractFactory("ComplianceDrivenRebalancing");
    const contract = await ComplianceDrivenRebalancing.deploy();
  
    console.log("ComplianceDrivenRebalancing deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
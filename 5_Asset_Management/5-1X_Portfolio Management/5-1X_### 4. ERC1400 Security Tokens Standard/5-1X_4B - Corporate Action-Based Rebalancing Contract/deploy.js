// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const CorporateActionBasedRebalancing = await ethers.getContractFactory("CorporateActionBasedRebalancing");
    const contract = await CorporateActionBasedRebalancing.deploy();
  
    console.log("CorporateActionBasedRebalancing deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
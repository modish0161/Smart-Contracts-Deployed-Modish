// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PerformanceBasedRebalancing = await ethers.getContractFactory("PerformanceBasedRebalancing");
    const contract = await PerformanceBasedRebalancing.deploy();
  
    console.log("PerformanceBasedRebalancing deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
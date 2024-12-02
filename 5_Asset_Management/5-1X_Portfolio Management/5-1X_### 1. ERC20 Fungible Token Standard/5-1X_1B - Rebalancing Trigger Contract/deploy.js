// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const RebalancingTrigger = await ethers.getContractFactory("RebalancingTrigger");
    const contract = await RebalancingTrigger.deploy();
  
    console.log("RebalancingTrigger deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
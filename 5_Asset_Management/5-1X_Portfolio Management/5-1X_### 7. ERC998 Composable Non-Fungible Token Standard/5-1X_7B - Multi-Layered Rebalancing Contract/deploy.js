// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const MultiLayeredRebalancing = await ethers.getContractFactory("MultiLayeredRebalancing");
    const contract = await MultiLayeredRebalancing.deploy();
  
    console.log("MultiLayeredRebalancing deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
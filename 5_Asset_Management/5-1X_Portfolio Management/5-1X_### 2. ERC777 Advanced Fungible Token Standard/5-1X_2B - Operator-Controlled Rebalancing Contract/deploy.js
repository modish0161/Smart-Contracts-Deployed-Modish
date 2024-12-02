// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const defaultOperators = []; // List of default operators, if any
  
    const OperatorControlledRebalancing = await ethers.getContractFactory("OperatorControlledRebalancing");
    const contract = await OperatorControlledRebalancing.deploy("Operator Controlled Portfolio Token", "OCPT", defaultOperators);
  
    console.log("OperatorControlledRebalancing deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  
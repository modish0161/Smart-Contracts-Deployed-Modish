// scripts/deploy.js

async function main() {
    // Get the contract factory
    const OperatorControlledProxyVoting = await ethers.getContractFactory("OperatorControlledProxyVoting");
  
    // Deployment parameters
    const name = "Operator Controlled Voting Token";
    const symbol = "OCVT";
    const defaultOperators = []; // Can add default operators here if needed
  
    // Deploy the contract with necessary parameters
    const operatorControlledProxyVoting = await OperatorControlledProxyVoting.deploy(name, symbol, defaultOperators);
  
    await operatorControlledProxyVoting.deployed();
  
    console.log("OperatorControlledProxyVoting deployed to:", operatorControlledProxyVoting.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
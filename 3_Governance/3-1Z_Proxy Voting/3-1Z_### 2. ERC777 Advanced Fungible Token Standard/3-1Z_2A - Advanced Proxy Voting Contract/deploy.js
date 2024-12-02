// scripts/deploy.js

async function main() {
    // Get the contract factory
    const AdvancedProxyVoting = await ethers.getContractFactory("AdvancedProxyVoting");
  
    // Deployment parameters
    const name = "Advanced Proxy Voting Token";
    const symbol = "APVT";
    const defaultOperators = []; // Can add default operators here if needed
  
    // Deploy the contract with necessary parameters
    const advancedProxyVoting = await AdvancedProxyVoting.deploy(name, symbol, defaultOperators);
  
    await advancedProxyVoting.deployed();
  
    console.log("AdvancedProxyVoting deployed to:", advancedProxyVoting.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
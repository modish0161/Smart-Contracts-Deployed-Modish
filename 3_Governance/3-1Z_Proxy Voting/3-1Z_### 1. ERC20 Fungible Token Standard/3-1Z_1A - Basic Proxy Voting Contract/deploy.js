// scripts/deploy.js

async function main() {
    // Get the contract factory
    const BasicProxyVoting = await ethers.getContractFactory("BasicProxyVoting");
  
    // Deployment parameters
    const name = "Basic Proxy Voting Token";
    const symbol = "BPVT";
  
    // Deploy the contract with necessary parameters
    const basicProxyVoting = await BasicProxyVoting.deploy(name, symbol);
  
    await basicProxyVoting.deployed();
  
    console.log("BasicProxyVoting deployed to:", basicProxyVoting.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
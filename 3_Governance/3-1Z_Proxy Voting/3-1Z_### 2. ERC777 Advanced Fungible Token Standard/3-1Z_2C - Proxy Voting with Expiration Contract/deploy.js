// scripts/deploy.js

async function main() {
    // Get the contract factory
    const ProxyVotingWithExpiration = await ethers.getContractFactory("ProxyVotingWithExpiration");
  
    // Deployment parameters
    const name = "Proxy Voting Token";
    const symbol = "PVT";
    const defaultOperators = []; // Can add default operators here if needed
  
    // Deploy the contract with necessary parameters
    const proxyVotingWithExpiration = await ProxyVotingWithExpiration.deploy(name, symbol, defaultOperators);
  
    await proxyVotingWithExpiration.deployed();
  
    console.log("ProxyVotingWithExpiration deployed to:", proxyVotingWithExpiration.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
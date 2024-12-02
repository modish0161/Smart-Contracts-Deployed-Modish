// scripts/deploy.js

async function main() {
    // Get the contract factory
    const ProxyVotingWithRevocation = await ethers.getContractFactory("ProxyVotingWithRevocation");
  
    // Deployment parameters
    const name = "Proxy Voting Token";
    const symbol = "PVT";
  
    // Deploy the contract with necessary parameters
    const proxyVotingWithRevocation = await ProxyVotingWithRevocation.deploy(name, symbol);
  
    await proxyVotingWithRevocation.deployed();
  
    console.log("ProxyVotingWithRevocation deployed to:", proxyVotingWithRevocation.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
// scripts/deploy.js

async function main() {
    // Get the contract factory
    const BatchProxyVoting = await ethers.getContractFactory("BatchProxyVoting");
  
    // Deploy the contract
    const batchProxyVoting = await BatchProxyVoting.deploy();
  
    await batchProxyVoting.deployed();
  
    console.log("BatchProxyVoting deployed to:", batchProxyVoting.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
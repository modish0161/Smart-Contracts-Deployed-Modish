// scripts/deploy.js

async function main() {
    // Get the contract factory
    const MultiTokenProxyVoting = await ethers.getContractFactory("MultiTokenProxyVoting");
  
    // Deploy the contract
    const multiTokenProxyVoting = await MultiTokenProxyVoting.deploy();
  
    await multiTokenProxyVoting.deployed();
  
    console.log("MultiTokenProxyVoting deployed to:", multiTokenProxyVoting.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
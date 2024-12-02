// scripts/deploy.js

async function main() {
    // Get the contract factory
    const SecurityTokenProxyVoting = await ethers.getContractFactory("SecurityTokenProxyVoting");
  
    // Deploy the contract
    const securityTokenProxyVoting = await SecurityTokenProxyVoting.deploy("SecurityToken", "STK", 1000000, []);
  
    await securityTokenProxyVoting.deployed();
  
    console.log("SecurityTokenProxyVoting deployed to:", securityTokenProxyVoting.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
// scripts/deploy.js

async function main() {
    const ComposableProxyVoting = await ethers.getContractFactory("ComposableProxyVoting");
  
    const contract = await ComposableProxyVoting.deploy("ComposableToken", "CTK");
  
    await contract.deployed();
  
    console.log("ComposableProxyVoting deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
// scripts/deploy.js

async function main() {
    const MultiLayerProxyVoting = await ethers.getContractFactory("MultiLayerProxyVoting");
  
    const contract = await MultiLayerProxyVoting.deploy("MultiLayerToken", "MLT");
  
    await contract.deployed();
  
    console.log("MultiLayerProxyVoting deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
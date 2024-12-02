// scripts/deploy.js

async function main() {
    // Get the contract factory
    const MultiAssetDAOGovernance = await ethers.getContractFactory("MultiAssetDAOGovernance");
  
    // Deploy the contract with the desired URI for metadata
    const uri = "https://example.com/metadata/{id}.json";
    const multiAssetDAOGovernance = await MultiAssetDAOGovernance.deploy(uri);
  
    await multiAssetDAOGovernance.deployed();
  
    console.log("MultiAssetDAOGovernance deployed to:", multiAssetDAOGovernance.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
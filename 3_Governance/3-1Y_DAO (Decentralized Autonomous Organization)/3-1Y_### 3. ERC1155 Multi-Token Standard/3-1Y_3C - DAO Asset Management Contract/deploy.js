// scripts/deploy.js

async function main() {
    // Get the contract factory
    const DAOAssetManagement = await ethers.getContractFactory("DAOAssetManagement");
  
    // Deploy the contract with the desired URI for metadata
    const uri = "https://example.com/metadata/{id}.json";
    const daoAssetManagement = await DAOAssetManagement.deploy(uri);
  
    await daoAssetManagement.deployed();
  
    console.log("DAOAssetManagement deployed to:", daoAssetManagement.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
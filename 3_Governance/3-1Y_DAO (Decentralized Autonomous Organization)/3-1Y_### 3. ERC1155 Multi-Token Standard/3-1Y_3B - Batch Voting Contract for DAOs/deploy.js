// scripts/deploy.js

async function main() {
    // Get the contract factory
    const BatchVotingDAO = await ethers.getContractFactory("BatchVotingDAO");
  
    // Deploy the contract with the desired URI for metadata
    const uri = "https://example.com/metadata/{id}.json";
    const batchVotingDAO = await BatchVotingDAO.deploy(uri);
  
    await batchVotingDAO.deployed();
  
    console.log("BatchVotingDAO deployed to:", batchVotingDAO.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
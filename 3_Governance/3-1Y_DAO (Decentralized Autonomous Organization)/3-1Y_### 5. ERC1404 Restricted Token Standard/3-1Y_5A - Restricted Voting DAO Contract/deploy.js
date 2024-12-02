// scripts/deploy.js

async function main() {
    // Get the contract factory
    const RestrictedVotingDAO = await ethers.getContractFactory("RestrictedVotingDAO");
  
    // Deployment parameters
    const restrictedTokenAddress = "0xYourRestrictedTokenAddress"; // Replace with the ERC1404 token address
    const votingDuration = 7 * 24 * 60 * 60; // 7 days
  
    // Deploy the contract with necessary parameters
    const restrictedVotingDAO = await RestrictedVotingDAO.deploy(
      restrictedTokenAddress, votingDuration
    );
  
    await restrictedVotingDAO.deployed();
  
    console.log("RestrictedVotingDAO deployed to:", restrictedVotingDAO.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
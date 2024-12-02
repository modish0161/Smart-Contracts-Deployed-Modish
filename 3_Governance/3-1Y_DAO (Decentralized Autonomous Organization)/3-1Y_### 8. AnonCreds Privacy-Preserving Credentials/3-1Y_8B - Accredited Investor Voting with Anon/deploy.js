// scripts/deploy.js

async function main() {
    // Get the contract factory
    const AccreditedInvestorVoting = await ethers.getContractFactory("AccreditedInvestorVoting");
  
    // Deployment parameters
    const governanceTokenAddress = "0xYourGovernanceTokenAddress"; // Replace with governance token address
    const anonCredsAddress = "0xYourAnonCredsContractAddress"; // Replace with AnonCreds contract address
    const votingDuration = 7 * 24 * 60 * 60; // 7 days
    const minimumTokenThreshold = 100; // Replace with desired minimum token threshold
    const merkleRoot = "0xYourMerkleRoot"; // Replace with the Merkle root
  
    // Deploy the contract with necessary parameters
    const accreditedInvestorVoting = await AccreditedInvestorVoting.deploy(
      governanceTokenAddress,
      anonCredsAddress,
      votingDuration,
      minimumTokenThreshold,
      merkleRoot
    );
  
    await accreditedInvestorVoting.deployed();
  
    console.log("AccreditedInvestorVoting deployed to:", accreditedInvestorVoting.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
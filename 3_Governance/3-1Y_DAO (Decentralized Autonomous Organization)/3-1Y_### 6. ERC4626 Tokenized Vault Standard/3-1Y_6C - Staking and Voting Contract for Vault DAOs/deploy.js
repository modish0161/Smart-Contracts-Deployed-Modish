// scripts/deploy.js

async function main() {
    // Get the contract factory
    const StakingAndVotingVaultDAO = await ethers.getContractFactory("StakingAndVotingVaultDAO");
  
    // Deployment parameters
    const assetAddress = "0xYourAssetAddress"; // Replace with the tokenized asset address
    const vaultName = "Staking and Voting Vault DAO";
    const vaultSymbol = "SVVD";
    const governanceTokenAddress = "0xYourGovernanceTokenAddress"; // Replace with the governance token address
    const votingDuration = 7 * 24 * 60 * 60; // 7 days
    const minimumStakeAmount = ethers.utils.parseEther("100"); // Replace with desired minimum stake amount
  
    // Deploy the contract with necessary parameters
    const stakingAndVotingVaultDAO = await StakingAndVotingVaultDAO.deploy(
      assetAddress, vaultName, vaultSymbol, governanceTokenAddress, votingDuration, minimumStakeAmount
    );
  
    await stakingAndVotingVaultDAO.deployed();
  
    console.log("StakingAndVotingVaultDAO deployed to:", stakingAndVotingVaultDAO.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
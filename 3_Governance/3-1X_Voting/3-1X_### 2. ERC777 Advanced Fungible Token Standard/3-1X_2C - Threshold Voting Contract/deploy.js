const { ethers } = require("hardhat");

async function main() {
    // Define contract variables
    const VotingTokenAddress = "<ERC777 Token Contract Address>";
    const VotingDuration = 604800; // 1 week in seconds
    const DefaultThreshold = 1000 * 10**18; // Threshold in tokens (e.g., 1000 tokens)

    // Get the contract factory and deploy
    const ThresholdVotingContract = await ethers.getContractFactory("ThresholdVotingContract");
    const thresholdVotingContract = await ThresholdVotingContract.deploy(VotingTokenAddress, VotingDuration, DefaultThreshold);

    // Wait for deployment to complete
    await thresholdVotingContract.deployed();

    console.log("ThresholdVotingContract deployed to:", thresholdVotingContract.address);
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

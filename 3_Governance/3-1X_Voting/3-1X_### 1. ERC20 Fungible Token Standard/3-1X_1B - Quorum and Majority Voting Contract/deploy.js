const { ethers } = require("hardhat");

async function main() {
    // Define contract variables
    const VotingTokenAddress = "<ERC20 Token Contract Address>";
    const VotingDuration = 604800; // 1 week in seconds
    const QuorumPercentage = 20; // 20% quorum

    // Get the contract factory and deploy
    const VotingContract = await ethers.getContractFactory("QuorumMajorityVotingContract");
    const votingContract = await VotingContract.deploy(VotingTokenAddress, VotingDuration, QuorumPercentage);

    // Wait for deployment to complete
    await votingContract.deployed();

    console.log("QuorumMajorityVotingContract deployed to:", votingContract.address);
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

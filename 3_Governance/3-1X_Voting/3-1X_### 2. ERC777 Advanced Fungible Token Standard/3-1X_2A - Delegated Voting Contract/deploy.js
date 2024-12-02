const { ethers } = require("hardhat");

async function main() {
    // Define contract variables
    const VotingTokenAddress = "<ERC777 Token Contract Address>";
    const VotingDuration = 604800; // 1 week in seconds
    const QuorumPercentage = 20; // 20% quorum

    // Get the contract factory and deploy
    const DelegatedVotingContract = await ethers.getContractFactory("DelegatedVotingContract");
    const delegatedVotingContract = await DelegatedVotingContract.deploy(VotingTokenAddress, VotingDuration, QuorumPercentage);

    // Wait for deployment to complete
    await delegatedVotingContract.deployed();

    console.log("DelegatedVotingContract deployed to:", delegatedVotingContract.address);
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

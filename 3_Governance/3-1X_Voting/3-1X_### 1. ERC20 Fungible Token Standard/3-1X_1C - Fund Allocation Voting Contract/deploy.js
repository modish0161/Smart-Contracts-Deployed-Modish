const { ethers } = require("hardhat");

async function main() {
    // Define contract variables
    const VotingTokenAddress = "<ERC20 Token Contract Address>";
    const VotingDuration = 604800; // 1 week in seconds
    const QuorumPercentage = 20; // 20% quorum

    // Get the contract factory and deploy
    const FundAllocationVotingContract = await ethers.getContractFactory("FundAllocationVotingContract");
    const fundAllocationVotingContract = await FundAllocationVotingContract.deploy(VotingTokenAddress, VotingDuration, QuorumPercentage);

    // Wait for deployment to complete
    await fundAllocationVotingContract.deployed();

    console.log("FundAllocationVotingContract deployed to:", fundAllocationVotingContract.address);
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

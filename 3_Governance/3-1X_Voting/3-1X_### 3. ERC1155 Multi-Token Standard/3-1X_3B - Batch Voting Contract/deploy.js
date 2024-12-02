const { ethers } = require("hardhat");

async function main() {
    // Define contract variables
    const VotingTokenAddress = "<ERC1155 Token Contract Address>";
    const VotingDuration = 604800; // 1 week in seconds

    // Get the contract factory and deploy
    const BatchVotingContract = await ethers.getContractFactory("BatchVotingContract");
    const batchVotingContract = await BatchVotingContract.deploy(VotingTokenAddress, VotingDuration);

    // Wait for deployment to complete
    await batchVotingContract.deployed();

    console.log("BatchVotingContract deployed to:", batchVotingContract.address);
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

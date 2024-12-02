const { ethers } = require("hardhat");

async function main() {
    // Define contract variables
    const VotingTokenAddress = "<ERC1404 Token Contract Address>";
    const VotingDuration = 604800; // 1 week in seconds

    // Get the contract factory and deploy
    const RestrictedVotingContract = await ethers.getContractFactory("RestrictedVotingContract");
    const restrictedVotingContract = await RestrictedVotingContract.deploy(VotingTokenAddress, VotingDuration);

    // Wait for deployment to complete
    await restrictedVotingContract.deployed();

    console.log("RestrictedVotingContract deployed to:", restrictedVotingContract.address);
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

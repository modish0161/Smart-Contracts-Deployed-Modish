const { ethers } = require("hardhat");

async function main() {
    // Define contract variables
    const VotingTokenAddress = "<ERC1400 Token Contract Address>";
    const VotingDuration = 604800; // 1 week in seconds

    // Get the contract factory and deploy
    const DividendsAndDistributionVotingContract = await ethers.getContractFactory("DividendsAndDistributionVotingContract");
    const dividendsAndDistributionVotingContract = await DividendsAndDistributionVotingContract.deploy(VotingTokenAddress, VotingDuration);

    // Wait for deployment to complete
    await dividendsAndDistributionVotingContract.deployed();

    console.log("DividendsAndDistributionVotingContract deployed to:", dividendsAndDistributionVotingContract.address);
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

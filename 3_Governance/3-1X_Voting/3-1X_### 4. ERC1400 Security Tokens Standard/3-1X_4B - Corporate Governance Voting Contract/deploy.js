const { ethers } = require("hardhat");

async function main() {
    // Define contract variables
    const VotingTokenAddress = "<ERC1400 Token Contract Address>";
    const VotingDuration = 604800; // 1 week in seconds

    // Get the contract factory and deploy
    const CorporateGovernanceVotingContract = await ethers.getContractFactory("CorporateGovernanceVotingContract");
    const corporateGovernanceVotingContract = await CorporateGovernanceVotingContract.deploy(VotingTokenAddress, VotingDuration);

    // Wait for deployment to complete
    await corporateGovernanceVotingContract.deployed();

    console.log("CorporateGovernanceVotingContract deployed to:", corporateGovernanceVotingContract.address);
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

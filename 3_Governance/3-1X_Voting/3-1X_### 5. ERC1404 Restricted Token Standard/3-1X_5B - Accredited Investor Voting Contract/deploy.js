const { ethers } = require("hardhat");

async function main() {
    // Define contract variables
    const VotingTokenAddress = "<ERC1404 Token Contract Address>";
    const VotingDuration = 604800; // 1 week in seconds

    // Get the contract factory and deploy
    const AccreditedInvestorVotingContract = await ethers.getContractFactory("AccreditedInvestorVotingContract");
    const accreditedInvestorVotingContract = await AccreditedInvestorVotingContract.deploy(VotingTokenAddress, VotingDuration);

    // Wait for deployment to complete
    await accreditedInvestorVotingContract.deployed();

    console.log("AccreditedInvestorVotingContract deployed to:", accreditedInvestorVotingContract.address);
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

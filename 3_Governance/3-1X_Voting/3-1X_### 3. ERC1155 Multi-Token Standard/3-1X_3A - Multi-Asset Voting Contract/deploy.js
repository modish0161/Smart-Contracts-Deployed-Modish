const { ethers } = require("hardhat");

async function main() {
    // Define contract variables
    const VotingTokenAddress = "<ERC1155 Token Contract Address>";
    const VotingDuration = 604800; // 1 week in seconds

    // Get the contract factory and deploy
    const MultiAssetVotingContract = await ethers.getContractFactory("MultiAssetVotingContract");
    const multiAssetVotingContract = await MultiAssetVotingContract.deploy(VotingTokenAddress, VotingDuration);

    // Wait for deployment to complete
    await multiAssetVotingContract.deployed();

    console.log("MultiAssetVotingContract deployed to:", multiAssetVotingContract.address);
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

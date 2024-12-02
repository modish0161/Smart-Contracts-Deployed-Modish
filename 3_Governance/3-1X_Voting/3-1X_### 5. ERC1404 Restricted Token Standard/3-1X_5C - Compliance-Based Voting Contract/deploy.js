// deploy.js
const { ethers } = require("hardhat");

async function main() {
    // Compile the contracts
    console.log("Compiling contracts...");
    await hre.run("compile");

    // Deploy the ERC1404 token contract
    console.log("Deploying ERC1404 voting token...");
    const ERC1404Token = await ethers.getContractFactory("ERC1404");
    const tokenName = "ComplianceVotingToken";
    const tokenSymbol = "CVT";
    const tokenDecimals = 18;
    const votingToken = await ERC1404Token.deploy(tokenName, tokenSymbol, tokenDecimals);
    await votingToken.deployed();
    console.log(`ERC1404 voting token deployed at: ${votingToken.address}`);

    // Deploy the ComplianceBasedVotingContract
    console.log("Deploying ComplianceBasedVotingContract...");
    const VotingContract = await ethers.getContractFactory("ComplianceBasedVotingContract");
    const votingDuration = 7 * 24 * 60 * 60; // 7 days in seconds
    const votingContract = await VotingContract.deploy(
        tokenName,
        tokenSymbol,
        tokenDecimals,
        votingToken.address,
        votingDuration
    );
    await votingContract.deployed();
    console.log(`ComplianceBasedVotingContract deployed at: ${votingContract.address}`);

    // Optional: Verify the contract on Etherscan (if using a public network and API key is configured)
    if (hre.network.name !== "hardhat" && hre.network.name !== "localhost") {
        console.log("Verifying contracts on Etherscan...");
        await hre.run("verify:verify", {
            address: votingToken.address,
            constructorArguments: [tokenName, tokenSymbol, tokenDecimals],
        });

        await hre.run("verify:verify", {
            address: votingContract.address,
            constructorArguments: [
                tokenName,
                tokenSymbol,
                tokenDecimals,
                votingToken.address,
                votingDuration,
            ],
        });
    }

    console.log("Deployment complete.");
}

// Run the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("Error during deployment:", error);
        process.exit(1);
    });

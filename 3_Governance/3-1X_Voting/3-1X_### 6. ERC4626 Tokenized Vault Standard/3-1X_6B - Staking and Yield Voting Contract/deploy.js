// deploy.js
const { ethers } = require("hardhat");

async function main() {
    // Compile the contracts
    console.log("Compiling contracts...");
    await hre.run("compile");

    // Deploy the ERC20 token for the ERC4626 Vault
    console.log("Deploying ERC20 token for the ERC4626 Vault...");
    const ERC20Token = await ethers.getContractFactory("ERC20");
    const tokenName = "Vault Token";
    const tokenSymbol = "VTK";
    const initialSupply = ethers.utils.parseEther("1000000"); // 1,000,000 tokens
    const erc20Token = await ERC20Token.deploy(tokenName, tokenSymbol, initialSupply);
    await erc20Token.deployed();
    console.log(`ERC20 token deployed at: ${erc20Token.address}`);

    // Deploy the ERC4626 Vault
    console.log("Deploying ERC4626 Vault...");
    const ERC4626Vault = await ethers.getContractFactory("ERC4626");
    const vaultName = "Yield Vault";
    const vaultSymbol = "YVLT";
    const erc4626Vault = await ERC4626Vault.deploy(erc20Token.address, vaultName, vaultSymbol);
    await erc4626Vault.deployed();
    console.log(`ERC4626 Vault deployed at: ${erc4626Vault.address}`);

    // Deploy the StakingAndYieldVotingContract
    console.log("Deploying StakingAndYieldVotingContract...");
    const VotingContract = await ethers.getContractFactory("StakingAndYieldVotingContract");
    const stakingAndYieldVotingContract = await VotingContract.deploy(erc4626Vault.address);
    await stakingAndYieldVotingContract.deployed();
    console.log(`StakingAndYieldVotingContract deployed at: ${stakingAndYieldVotingContract.address}`);

    // Optional: Verify the contracts on Etherscan
    if (hre.network.name !== "hardhat" && hre.network.name !== "localhost") {
        console.log("Verifying contracts on Etherscan...");
        await hre.run("verify:verify", {
            address: erc20Token.address,
            constructorArguments: [tokenName, tokenSymbol, initialSupply],
        });

        await hre.run("verify:verify", {
            address: erc4626Vault.address,
            constructorArguments: [erc20Token.address, vaultName, vaultSymbol],
        });

        await hre.run("verify:verify", {
            address: stakingAndYieldVotingContract.address,
            constructorArguments: [erc4626Vault.address],
        });
    }

    console.log("Deployment complete.");
}

// Run the deployment script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("Error during deployment:", error);
        process.exit(1);
    });

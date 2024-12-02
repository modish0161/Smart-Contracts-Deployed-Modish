async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const StakingYieldVault = await ethers.getContractFactory("StakingYieldVault");
    const asset = "0xYourUnderlyingAssetAddress"; // Address of the underlying ERC20 token (e.g., stablecoin or security token)
    const rewardToken = "0xYourRewardTokenAddress"; // Address of the reward token (e.g., yield token)
    const vault = await StakingYieldVault.deploy(
        asset,
        rewardToken,
        "Staking Vault Token",
        "SVT"
    );

    console.log("StakingYieldVault deployed to:", vault.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

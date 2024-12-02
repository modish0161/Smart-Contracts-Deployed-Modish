async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const TokenizedSecuritiesVault = await ethers.getContractFactory("TokenizedSecuritiesVault");
    const vault = await TokenizedSecuritiesVault.deploy(
        "0xYourUnderlyingAssetAddress", // Address of the underlying ERC20 token
        "Vault Token Name",
        "VTN"
    );

    console.log("TokenizedSecuritiesVault deployed to:", vault.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

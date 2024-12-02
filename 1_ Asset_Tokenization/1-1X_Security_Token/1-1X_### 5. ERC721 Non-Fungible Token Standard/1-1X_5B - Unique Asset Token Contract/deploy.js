async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const UniqueAssetToken = await ethers.getContractFactory("UniqueAssetToken");
    const token = await UniqueAssetToken.deploy(
        "UniqueAssetToken", // Token name
        "UAT" // Token symbol
    );

    console.log("UniqueAssetToken deployed to:", token.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

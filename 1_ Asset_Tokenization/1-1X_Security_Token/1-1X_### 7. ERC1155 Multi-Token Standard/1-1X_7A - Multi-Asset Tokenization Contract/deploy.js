async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const MultiAssetTokenization = await ethers.getContractFactory("MultiAssetTokenization");
    const multiAssetContract = await MultiAssetTokenization.deploy("https://api.example.com/metadata/");

    console.log("MultiAssetTokenization deployed to:", multiAssetContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

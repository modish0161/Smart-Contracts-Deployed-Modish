async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const UniqueAssetTokenization = await ethers.getContractFactory("UniqueAssetTokenization");
    const contract = await UniqueAssetTokenization.deploy();

    console.log("UniqueAssetTokenization deployed to:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

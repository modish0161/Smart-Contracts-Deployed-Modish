async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const RealEstateTokenizationContract = await ethers.getContractFactory("RealEstateTokenizationContract");
    const token = await RealEstateTokenizationContract.deploy(
        "RealEstateToken", // Token name
        "RET" // Token symbol
    );

    console.log("RealEstateTokenizationContract deployed to:", token.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

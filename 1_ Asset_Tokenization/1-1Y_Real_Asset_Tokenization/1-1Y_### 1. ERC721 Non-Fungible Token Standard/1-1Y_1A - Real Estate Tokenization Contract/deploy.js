async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const RealEstateTokenization = await ethers.getContractFactory("RealEstateTokenization");
    const contract = await RealEstateTokenization.deploy();

    console.log("RealEstateTokenization deployed to:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

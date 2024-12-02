async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const RealEstatePortfolioTokenization = await ethers.getContractFactory("RealEstatePortfolioTokenization");
    const contract = await RealEstatePortfolioTokenization.deploy("https://api.example.com/metadata/{id}.json");

    console.log("RealEstatePortfolioTokenization deployed to:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

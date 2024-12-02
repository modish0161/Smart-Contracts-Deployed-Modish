async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const ComposableRealEstatePortfolio = await ethers.getContractFactory("ComposableRealEstatePortfolio");
    const portfolio = await ComposableRealEstatePortfolio.deploy(
        "ComposableRealEstatePortfolio", // Token name
        "CREP" // Token symbol
    );

    console.log("ComposableRealEstatePortfolio deployed to:", portfolio.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const PhysicalCommodityTokenization = await ethers.getContractFactory("PhysicalCommodityTokenization");
    const contract = await PhysicalCommodityTokenization.deploy();

    console.log("PhysicalCommodityTokenization deployed to:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

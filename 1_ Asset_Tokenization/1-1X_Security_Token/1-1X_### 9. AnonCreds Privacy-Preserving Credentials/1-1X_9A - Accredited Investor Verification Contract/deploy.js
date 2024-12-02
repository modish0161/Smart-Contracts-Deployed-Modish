async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const AccreditedInvestorVerification = await ethers.getContractFactory("AccreditedInvestorVerification");
    const contract = await AccreditedInvestorVerification.deploy();

    console.log("AccreditedInvestorVerification deployed to:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

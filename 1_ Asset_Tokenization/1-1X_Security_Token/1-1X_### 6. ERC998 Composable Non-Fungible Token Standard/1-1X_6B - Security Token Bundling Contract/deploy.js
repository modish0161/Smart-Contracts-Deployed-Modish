async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const SecurityTokenBundling = await ethers.getContractFactory("SecurityTokenBundling");
    const bundlingContract = await SecurityTokenBundling.deploy(
        "SecurityTokenBundling", // Token name
        "STBC" // Token symbol
    );

    console.log("SecurityTokenBundling deployed to:", bundlingContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

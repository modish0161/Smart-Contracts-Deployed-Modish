async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const OperatorControlContract = await ethers.getContractFactory("OperatorControlContract");
    const token = await OperatorControlContract.deploy(
        "OperatorControlToken", // Token name
        "OCT", // Token symbol
        [] // Default operators
    );

    console.log("OperatorControlContract deployed to:", token.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

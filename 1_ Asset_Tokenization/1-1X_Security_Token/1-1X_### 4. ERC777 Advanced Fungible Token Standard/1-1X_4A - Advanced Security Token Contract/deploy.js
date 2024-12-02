async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const AdvancedSecurityTokenContract = await ethers.getContractFactory("AdvancedSecurityTokenContract");
    const token = await AdvancedSecurityTokenContract.deploy(
        "AdvancedSecurityToken", // Token name
        "AST", // Token symbol
        [] // Default operators
    );

    console.log("AdvancedSecurityTokenContract deployed to:", token.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

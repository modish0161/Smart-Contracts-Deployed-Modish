async function main() {
    const SecurityTokenIssuance = await ethers.getContractFactory("SecurityTokenIssuance");
    const securityToken = await SecurityTokenIssuance.deploy("My Security Token", "MST", 18, 1000000);
    await securityToken.deployed();
    console.log("SecurityTokenIssuance deployed to:", securityToken.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

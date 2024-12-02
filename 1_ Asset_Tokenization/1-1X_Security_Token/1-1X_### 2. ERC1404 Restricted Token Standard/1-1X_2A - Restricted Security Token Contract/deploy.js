async function main() {
    const RestrictedSecurityTokenContract = await ethers.getContractFactory("RestrictedSecurityTokenContract");
    const restrictedSecurityTokenContract = await RestrictedSecurityTokenContract.deploy("Restricted Security Token", "RST", 18, 1000000);
    await restrictedSecurityTokenContract.deployed();
    console.log("RestrictedSecurityTokenContract deployed to:", restrictedSecurityTokenContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

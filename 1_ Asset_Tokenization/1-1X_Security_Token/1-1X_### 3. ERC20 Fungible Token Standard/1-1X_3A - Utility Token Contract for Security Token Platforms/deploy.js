async function main() {
    const UtilityTokenContract = await ethers.getContractFactory("UtilityTokenContract");
    const utilityTokenContract = await UtilityTokenContract.deploy(
        "Utility Token", // Token name
        "UTK", // Token symbol
        1000000 // Initial supply
    );
    await utilityTokenContract.deployed();
    console.log("UtilityTokenContract deployed to:", utilityTokenContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

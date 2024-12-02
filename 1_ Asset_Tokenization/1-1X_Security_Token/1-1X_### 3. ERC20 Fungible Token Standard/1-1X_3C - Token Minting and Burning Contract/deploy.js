async function main() {
    const TokenMintingAndBurningContract = await ethers.getContractFactory("TokenMintingAndBurningContract");
    const tokenContract = await TokenMintingAndBurningContract.deploy(
        "MintBurnToken", // Token name
        "MBT", // Token symbol
        1000000 // Initial supply
    );
    await tokenContract.deployed();
    console.log("TokenMintingAndBurningContract deployed to:", tokenContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

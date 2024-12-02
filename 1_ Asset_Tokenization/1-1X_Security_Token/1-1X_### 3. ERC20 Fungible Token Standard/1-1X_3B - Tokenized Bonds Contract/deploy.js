async function main() {
    const TokenizedBondsContract = await ethers.getContractFactory("TokenizedBondsContract");
    const tokenizedBondsContract = await TokenizedBondsContract.deploy(
        "Tokenized Bond", // Token name
        "TBOND", // Token symbol
        1000000, // Initial supply
        Math.floor(Date.now() / 1000) + 365 * 24 * 60 * 60 // Maturity date (1 year from now)
    );
    await tokenizedBondsContract.deployed();
    console.log("TokenizedBondsContract deployed to:", tokenizedBondsContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

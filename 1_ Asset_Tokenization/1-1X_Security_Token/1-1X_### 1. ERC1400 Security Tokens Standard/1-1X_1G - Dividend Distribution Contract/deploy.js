async function main() {
    const DividendDistributionContract = await ethers.getContractFactory("DividendDistributionContract");
    const dividendToken = "0xYourDividendTokenAddress"; // Replace with your dividend token address
    const dividendDistributionContract = await DividendDistributionContract.deploy("Dividend Security Token", "DST", 18, 1000000, dividendToken);
    await dividendDistributionContract.deployed();
    console.log("DividendDistributionContract deployed to:", dividendDistributionContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

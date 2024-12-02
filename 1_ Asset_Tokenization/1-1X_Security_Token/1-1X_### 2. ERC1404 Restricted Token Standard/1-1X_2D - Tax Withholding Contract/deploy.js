async function main() {
    const TaxWithholdingContract = await ethers.getContractFactory("TaxWithholdingContract");
    const taxWithholdingContract = await TaxWithholdingContract.deploy(
        "Tax Withholding Token",
        "TWT",
        18,
        1000000,
        5 // Initial tax rate of 5%
    );
    await taxWithholdingContract.deployed();
    console.log("TaxWithholdingContract deployed to:", taxWithholdingContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

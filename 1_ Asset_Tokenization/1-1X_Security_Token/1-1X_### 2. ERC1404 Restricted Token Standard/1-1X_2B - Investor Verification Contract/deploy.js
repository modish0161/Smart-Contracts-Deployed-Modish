async function main() {
    const InvestorVerificationContract = await ethers.getContractFactory("InvestorVerificationContract");
    const investorVerificationContract = await InvestorVerificationContract.deploy("Investor Verification Token", "IVT", 18, 1000000);
    await investorVerificationContract.deployed();
    console.log("InvestorVerificationContract deployed to:", investorVerificationContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

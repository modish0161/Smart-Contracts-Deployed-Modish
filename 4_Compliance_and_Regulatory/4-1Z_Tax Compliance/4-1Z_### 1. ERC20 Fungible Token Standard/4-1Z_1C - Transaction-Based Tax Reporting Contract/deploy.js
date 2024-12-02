const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const TransactionBasedTaxReportingContract = await hre.ethers.getContractFactory("TransactionBasedTaxReportingContract");
    const initialSupply = hre.ethers.utils.parseUnits("1000000", 18); // Initial supply of 1,000,000 tokens
    const taxRate = 500; // Tax rate of 5%
    const taxAuthority = "0xYourTaxAuthorityAddress"; // Replace with actual tax authority address
    const reportingInterval = 86400; // Reporting interval of 1 day in seconds

    const contract = await TransactionBasedTaxReportingContract.deploy("TaxToken", "TAX", initialSupply, taxRate, taxAuthority, reportingInterval);

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

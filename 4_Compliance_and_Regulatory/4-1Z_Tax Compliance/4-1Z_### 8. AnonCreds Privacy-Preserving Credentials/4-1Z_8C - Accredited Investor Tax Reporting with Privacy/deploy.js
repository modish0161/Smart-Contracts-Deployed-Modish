const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const AccreditedInvestorTaxReportingWithPrivacy = await hre.ethers.getContractFactory("AccreditedInvestorTaxReportingWithPrivacy");

    const contract = await AccreditedInvestorTaxReportingWithPrivacy.deploy();

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

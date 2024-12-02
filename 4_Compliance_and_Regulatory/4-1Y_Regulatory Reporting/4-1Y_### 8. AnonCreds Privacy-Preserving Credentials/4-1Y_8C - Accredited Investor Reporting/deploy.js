const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const AccreditedInvestorReportingWithPrivacy = await hre.ethers.getContractFactory("AccreditedInvestorReportingWithPrivacy");
    const authorityAddress = "0xYourAuthorityAddress"; // Replace with actual authority address

    const contract = await AccreditedInvestorReportingWithPrivacy.deploy(authorityAddress);

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

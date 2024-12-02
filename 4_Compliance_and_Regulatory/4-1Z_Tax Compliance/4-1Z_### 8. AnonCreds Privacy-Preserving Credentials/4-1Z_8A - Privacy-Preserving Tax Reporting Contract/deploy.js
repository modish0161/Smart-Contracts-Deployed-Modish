const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const PrivacyPreservingTaxReportingContract = await hre.ethers.getContractFactory("PrivacyPreservingTaxReportingContract");
    const initialTaxAuthority = "0xTaxAuthorityAddress"; // Replace with the actual tax authority address

    const contract = await PrivacyPreservingTaxReportingContract.deploy(initialTaxAuthority);

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

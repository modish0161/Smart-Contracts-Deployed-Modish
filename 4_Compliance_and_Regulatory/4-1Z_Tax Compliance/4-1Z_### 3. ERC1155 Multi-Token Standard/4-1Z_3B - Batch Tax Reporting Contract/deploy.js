const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const BatchTaxReportingContract = await hre.ethers.getContractFactory("BatchTaxReportingContract");
    const taxAuthority = "0xYourTaxAuthorityAddress"; // Replace with actual tax authority address

    const contract = await BatchTaxReportingContract.deploy(
        "https://api.example.com/metadata/{id}.json", // URI for metadata
        taxAuthority
    );

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

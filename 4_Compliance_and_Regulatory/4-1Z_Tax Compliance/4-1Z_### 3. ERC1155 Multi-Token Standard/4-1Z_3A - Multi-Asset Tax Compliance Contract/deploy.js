const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const MultiAssetTaxComplianceContract = await hre.ethers.getContractFactory("MultiAssetTaxComplianceContract");
    const taxAuthority = "0xYourTaxAuthorityAddress"; // Replace with actual tax authority address

    const contract = await MultiAssetTaxComplianceContract.deploy(
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

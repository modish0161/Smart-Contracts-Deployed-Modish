const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const TaxWithholdingComplianceContract = await hre.ethers.getContractFactory("TaxWithholdingComplianceContract");
    const controllers = ["0xControllerAddress1", "0xControllerAddress2"]; // Replace with actual controller addresses
    const initialTaxAuthority = "0xTaxAuthorityAddress"; // Replace with actual tax authority address

    const contract = await TaxWithholdingComplianceContract.deploy(
        "RestrictedToken", // Name of the restricted token
        "RST", // Symbol of the restricted token
        controllers,
        initialTaxAuthority
    );

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

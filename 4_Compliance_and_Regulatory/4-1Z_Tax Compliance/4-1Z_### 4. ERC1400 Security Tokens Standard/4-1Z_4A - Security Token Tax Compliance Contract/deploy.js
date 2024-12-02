const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const SecurityTokenTaxComplianceContract = await hre.ethers.getContractFactory("SecurityTokenTaxComplianceContract");
    const controllers = ["0xControllerAddress1", "0xControllerAddress2"]; // Replace with actual controller addresses
    const taxAuthority = "0xYourTaxAuthorityAddress"; // Replace with actual tax authority address

    const contract = await SecurityTokenTaxComplianceContract.deploy(
        "SecurityToken", // Name of the security token
        "SEC", // Symbol of the security token
        controllers,
        taxAuthority
    );

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

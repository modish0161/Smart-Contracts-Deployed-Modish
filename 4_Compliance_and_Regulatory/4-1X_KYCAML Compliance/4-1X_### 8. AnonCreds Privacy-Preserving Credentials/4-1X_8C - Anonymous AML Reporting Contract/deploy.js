const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const AMLComplianceOfficer = "0xYourComplianceOfficerAddress"; // Replace with actual AML compliance officer address

    const AnonymousAMLReporting = await hre.ethers.getContractFactory("AnonymousAMLReporting");
    const contract = await AnonymousAMLReporting.deploy(AMLComplianceOfficer);

    await contract.deployed();
    console.log("AnonymousAMLReporting deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});

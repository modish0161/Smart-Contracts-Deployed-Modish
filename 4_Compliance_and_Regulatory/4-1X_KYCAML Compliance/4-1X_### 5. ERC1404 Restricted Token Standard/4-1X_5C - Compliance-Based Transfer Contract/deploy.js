const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const complianceOfficer = deployer.address; // For demo purposes

    const ComplianceBasedTransferContract = await hre.ethers.getContractFactory("ComplianceBasedTransferContract");
    const contract = await ComplianceBasedTransferContract.deploy(complianceOfficer);

    await contract.deployed();
    console.log("ComplianceBasedTransferContract deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});

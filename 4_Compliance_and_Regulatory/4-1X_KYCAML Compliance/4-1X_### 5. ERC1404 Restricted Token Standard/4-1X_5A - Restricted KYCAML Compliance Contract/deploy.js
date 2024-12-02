const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const complianceOfficer = deployer.address; // For demo purposes

    const RestrictedKYCAMLCompliance = await hre.ethers.getContractFactory("RestrictedKYCAMLCompliance");
    const contract = await RestrictedKYCAMLCompliance.deploy(complianceOfficer);

    await contract.deployed();
    console.log("RestrictedKYCAMLCompliance deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});

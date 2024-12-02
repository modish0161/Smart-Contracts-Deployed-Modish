const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const complianceOfficer = deployer.address; // Use deployer as compliance officer for demo purposes

    const AMLComplianceMonitoring = await hre.ethers.getContractFactory("AMLComplianceMonitoring");
    const contract = await AMLComplianceMonitoring.deploy(complianceOfficer);

    await contract.deployed();
    console.log("AMLComplianceMonitoring deployed to:", contract.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});

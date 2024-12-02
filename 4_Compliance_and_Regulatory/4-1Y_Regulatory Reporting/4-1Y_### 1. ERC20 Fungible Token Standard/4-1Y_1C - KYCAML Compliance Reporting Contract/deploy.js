const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const name = "ComplianceToken";
    const symbol = "COMPLY";
    const KYCAMLComplianceReporting = await hre.ethers.getContractFactory("KYCAMLComplianceReporting");
    const contract = await KYCAMLComplianceReporting.deploy(name, symbol);

    await contract.deployed();
    console.log("KYCAMLComplianceReporting deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});

const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const InvestorComplianceReporting = await hre.ethers.getContractFactory("InvestorComplianceReporting");
    const contract = await InvestorComplianceReporting.deploy("Compliance Token", "CMP");

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

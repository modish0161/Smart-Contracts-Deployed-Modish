const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const defaultOperators = [];
    const complianceOfficer = deployer.address; // Use deployer as compliance officer for demo purposes

    const AdvancedKYCAMLComplianceContract = await hre.ethers.getContractFactory("AdvancedKYCAMLComplianceContract");
    const contract = await AdvancedKYCAMLComplianceContract.deploy(defaultOperators, complianceOfficer);

    await contract.deployed();
    console.log("AdvancedKYCAMLComplianceContract deployed to:", contract.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});

const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const name = "SecurityToken";
    const symbol = "STK";
    const controllers = []; // List of controller addresses for ERC1400 partition management
    const complianceOfficer = deployer.address; // Use deployer as compliance officer for demo purposes

    const SecurityTokenKYCAMLComplianceContract = await hre.ethers.getContractFactory("SecurityTokenKYCAMLComplianceContract");
    const contract = await SecurityTokenKYCAMLComplianceContract.deploy(name, symbol, controllers, complianceOfficer);

    await contract.deployed();
    console.log("SecurityTokenKYCAMLComplianceContract deployed to:", contract.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});

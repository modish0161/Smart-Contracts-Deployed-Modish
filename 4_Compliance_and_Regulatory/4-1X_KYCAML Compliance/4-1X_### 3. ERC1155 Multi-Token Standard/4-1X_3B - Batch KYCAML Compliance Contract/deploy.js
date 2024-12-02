const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const complianceOfficer = deployer.address; // Use deployer as compliance officer for demo purposes
    const uri = "https://example.com/metadata/{id}.json"; // Metadata URI

    const BatchKYCAMLComplianceContract = await hre.ethers.getContractFactory("BatchKYCAMLComplianceContract");
    const contract = await BatchKYCAMLComplianceContract.deploy(uri, complianceOfficer);

    await contract.deployed();
    console.log("BatchKYCAMLComplianceContract deployed to:", contract.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});

const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const complianceOfficer = deployer.address; // Use deployer as compliance officer for demo purposes
    const uri = "https://example.com/metadata/{id}.json"; // Metadata URI

    const MultiAssetKYCAMLComplianceContract = await hre.ethers.getContractFactory("MultiAssetKYCAMLComplianceContract");
    const contract = await MultiAssetKYCAMLComplianceContract.deploy(uri, complianceOfficer);

    await contract.deployed();
    console.log("MultiAssetKYCAMLComplianceContract deployed to:", contract.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});

const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const complianceOfficer = deployer.address; // Use deployer as compliance officer for demo purposes

    const TransferRestrictionsKYCAML = await hre.ethers.getContractFactory("TransferRestrictionsKYCAML");
    const contract = await TransferRestrictionsKYCAML.deploy(complianceOfficer);

    await contract.deployed();
    console.log("TransferRestrictionsKYCAML deployed to:", contract.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});

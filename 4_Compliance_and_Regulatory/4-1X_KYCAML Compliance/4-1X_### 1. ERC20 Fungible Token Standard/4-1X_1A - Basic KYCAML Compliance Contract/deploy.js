const hre = require("hardhat");

async function main() {
    // Define deployment parameters
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const BasicKYCAMLComplianceContract = await hre.ethers.getContractFactory("BasicKYCAMLComplianceContract");
    const contract = await BasicKYCAMLComplianceContract.deploy("TokenName", "TKN", deployer.address);

    await contract.deployed();

    console.log("BasicKYCAMLComplianceContract deployed to:", contract.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});

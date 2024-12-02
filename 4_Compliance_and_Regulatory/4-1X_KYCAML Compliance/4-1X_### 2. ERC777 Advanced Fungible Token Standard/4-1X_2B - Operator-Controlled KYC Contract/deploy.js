const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const defaultOperators = [];
    const kycOperator = deployer.address; // Use deployer as KYC operator for demo purposes

    const OperatorControlledKYCContract = await hre.ethers.getContractFactory("OperatorControlledKYCContract");
    const contract = await OperatorControlledKYCContract.deploy(defaultOperators, kycOperator);

    await contract.deployed();
    console.log("OperatorControlledKYCContract deployed to:", contract.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});

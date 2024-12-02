const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const defaultOperators = [];
    const amlOfficer = deployer.address; // Use deployer as AML officer for demo purposes
    const largeTransactionThreshold = hre.ethers.utils.parseUnits("1000", 18); // Example: 1000 tokens
    const frequentTransactionLimit = 5; // Example: 5 transactions
    const timeWindow = 24 * 60 * 60; // Example: 24 hours

    const TransactionMonitoringAndAMLContract = await hre.ethers.getContractFactory("TransactionMonitoringAndAMLContract");
    const contract = await TransactionMonitoringAndAMLContract.deploy(
        defaultOperators,
        amlOfficer,
        largeTransactionThreshold,
        frequentTransactionLimit,
        timeWindow
    );

    await contract.deployed();
    console.log("TransactionMonitoringAndAMLContract deployed to:", contract.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});

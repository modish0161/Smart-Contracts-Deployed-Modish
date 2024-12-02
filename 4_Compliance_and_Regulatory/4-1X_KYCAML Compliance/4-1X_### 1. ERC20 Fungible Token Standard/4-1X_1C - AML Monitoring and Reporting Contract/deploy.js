const hre = require("hardhat");

async function main() {
    // Define deployment parameters
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    // Set initial parameters
    const transactionThreshold = hre.ethers.utils.parseUnits("1000", 18); // Example threshold: 1000 tokens
    const dailyTransferLimit = hre.ethers.utils.parseUnits("5000", 18); // Example limit: 5000 tokens per day

    const AMLMonitoringAndReportingContract = await hre.ethers.getContractFactory("AMLMonitoringAndReportingContract");
    const contract = await AMLMonitoringAndReportingContract.deploy(
        "AMLToken", 
        "AML", 
        deployer.address,
        transactionThreshold,
        dailyTransferLimit
    );

    await contract.deployed();

    console.log("AMLMonitoringAndReportingContract deployed to:", contract.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});

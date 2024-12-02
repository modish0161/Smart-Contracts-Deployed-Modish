const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const OwnershipReporting = await hre.ethers.getContractFactory("OwnershipReportingContract");
    const contract = await OwnershipReporting.deploy(
        "Security Token",
        "STK",
        [],
        [] // Initialize with empty controllers and partitions
    );

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

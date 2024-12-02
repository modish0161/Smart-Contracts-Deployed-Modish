const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const CapitalGainsTaxReportingContract = await hre.ethers.getContractFactory("CapitalGainsTaxReportingContract");
    const controllers = ["0xControllerAddress1", "0xControllerAddress2"]; // Replace with actual controller addresses
    const priceFeedAddress = "0xChainlinkPriceFeedAddress"; // Replace with actual Chainlink price feed address
    const initialTaxRate = 1500; // Initial tax rate set to 15%

    const contract = await CapitalGainsTaxReportingContract.deploy(
        "SecurityToken", // Name of the security token
        "SEC", // Symbol of the security token
        controllers,
        priceFeedAddress,
        initialTaxRate
    );

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

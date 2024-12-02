const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const name = "SecurityToken";
    const symbol = "STKN";

    const SecurityToken = await hre.ethers.getContractFactory("SecurityTokenRegulatoryReportingContract");
    const contract = await SecurityToken.deploy(name, symbol);

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

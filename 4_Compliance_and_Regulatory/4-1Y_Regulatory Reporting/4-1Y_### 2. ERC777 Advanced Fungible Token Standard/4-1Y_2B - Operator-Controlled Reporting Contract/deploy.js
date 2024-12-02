const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const name = "OperatorControlledToken";
    const symbol = "OCT777";
    const defaultOperators = []; // Default operators, can be left empty or defined as needed
    const Contract = await hre.ethers.getContractFactory("OperatorControlledReporting");
    const contract = await Contract.deploy(name, symbol, defaultOperators);

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

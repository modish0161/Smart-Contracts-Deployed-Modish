const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const ComposableTokenTaxComplianceContract = await hre.ethers.getContractFactory("ComposableTokenTaxComplianceContract");
    const initialTaxAuthority = "0xTaxAuthorityAddress"; // Replace with the actual tax authority address

    const contract = await ComposableTokenTaxComplianceContract.deploy(
        "ComposableToken", // Name of the composable token
        "CTK", // Symbol of the composable token
        initialTaxAuthority
    );

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

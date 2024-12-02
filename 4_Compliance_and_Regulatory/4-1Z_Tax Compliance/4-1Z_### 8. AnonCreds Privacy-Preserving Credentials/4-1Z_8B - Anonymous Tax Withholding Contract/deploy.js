const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const AnonymousTaxWithholdingContract = await hre.ethers.getContractFactory("AnonymousTaxWithholdingContract");
    const initialTaxAuthority = "0xTaxAuthorityAddress"; // Replace with the actual tax authority address

    const contract = await AnonymousTaxWithholdingContract.deploy(initialTaxAuthority);

    await contract.deployed();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

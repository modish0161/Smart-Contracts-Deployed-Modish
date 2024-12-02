const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const AccreditedInvestorVerificationWithPrivacy = await hre.ethers.getContractFactory("AccreditedInvestorVerificationWithPrivacy");
    const contract = await AccreditedInvestorVerificationWithPrivacy.deploy();

    await contract.deployed();
    console.log("AccreditedInvestorVerificationWithPrivacy deployed to:", contract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});

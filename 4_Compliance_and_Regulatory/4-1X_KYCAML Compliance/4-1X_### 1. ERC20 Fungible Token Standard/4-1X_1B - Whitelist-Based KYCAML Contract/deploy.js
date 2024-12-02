const hre = require("hardhat");

async function main() {
    // Define deployment parameters
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const WhitelistBasedKYCAMLContract = await hre.ethers.getContractFactory("WhitelistBasedKYCAMLContract");
    const contract = await WhitelistBasedKYCAMLContract.deploy("WhitelistToken", "WLT", deployer.address);

    await contract.deployed();

    console.log("WhitelistBasedKYCAMLContract deployed to:", contract.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});

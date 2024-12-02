const hre = require("hardhat");

async function main() {
  const GovernanceETFToken = await hre.ethers.getContractFactory("GovernanceETFToken");
  const governanceETFToken = await GovernanceETFToken.deploy();
  await governanceETFToken.deployed();
  console.log("Governance Contract deployed to:", governanceETFToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

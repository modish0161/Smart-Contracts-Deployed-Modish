const hre = require("hardhat");

async function main() {
  const initialSupply = 1000000; // Set initial supply as needed
  const RestrictedETFToken = await hre.ethers.getContractFactory("RestrictedETFToken");
  const restrictedETFToken = await RestrictedETFToken.deploy(initialSupply);
  await restrictedETFToken.deployed();
  console.log("Restricted ETF Token Contract deployed to:", restrictedETFToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

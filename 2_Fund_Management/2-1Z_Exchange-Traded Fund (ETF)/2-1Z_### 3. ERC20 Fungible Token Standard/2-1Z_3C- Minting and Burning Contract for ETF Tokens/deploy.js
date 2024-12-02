const hre = require("hardhat");

async function main() {
  const MintingBurningETFToken = await hre.ethers.getContractFactory("MintingBurningETFToken");
  const mintingBurningETFToken = await MintingBurningETFToken.deploy();
  await mintingBurningETFToken.deployed();
  console.log("Minting and Burning Contract deployed to:", mintingBurningETFToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

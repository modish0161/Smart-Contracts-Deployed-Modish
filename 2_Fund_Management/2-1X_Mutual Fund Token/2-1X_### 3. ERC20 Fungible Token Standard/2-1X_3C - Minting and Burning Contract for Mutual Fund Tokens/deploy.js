const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const MintingAndBurning = await hre.ethers.getContractFactory("MintingAndBurning");
  const mintingAndBurning = await MintingAndBurning.deploy(
    "Mutual Fund Token", // Token name
    "MFT",               // Token symbol
    1000000 * 10 ** 18   // Initial supply (1 million tokens)
  );

  await mintingAndBurning.deployed();
  console.log("Mutual Fund Token deployed to:", mintingAndBurning.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

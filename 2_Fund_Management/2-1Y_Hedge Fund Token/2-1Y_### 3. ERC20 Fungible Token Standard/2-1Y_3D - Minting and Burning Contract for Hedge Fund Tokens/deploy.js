const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const MintingBurningHedgeFund = await hre.ethers.getContractFactory("MintingBurningHedgeFund");
  const token = await MintingBurningHedgeFund.deploy("Hedge Fund Token", "HFT");

  await token.deployed();
  console.log("Minting and Burning Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

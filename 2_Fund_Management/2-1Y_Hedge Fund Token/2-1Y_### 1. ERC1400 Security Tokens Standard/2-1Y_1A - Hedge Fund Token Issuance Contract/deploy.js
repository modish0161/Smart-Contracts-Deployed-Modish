const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const MockERC20 = await hre.ethers.getContractFactory("MockERC20");
  const underlyingAsset = await MockERC20.deploy("Hedge Fund Token", "HFT", 18, 1000000);
  await underlyingAsset.deployed();

  console.log("Underlying Asset deployed to:", underlyingAsset.address);

  const HedgeFundTokenIssuance = await hre.ethers.getContractFactory("HedgeFundTokenIssuance");
  const hedgeFundTokenIssuance = await HedgeFundTokenIssuance.deploy(underlyingAsset.address);

  await hedgeFundTokenIssuance.deployed();
  console.log("Hedge Fund Token Issuance deployed to:", hedgeFundTokenIssuance.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

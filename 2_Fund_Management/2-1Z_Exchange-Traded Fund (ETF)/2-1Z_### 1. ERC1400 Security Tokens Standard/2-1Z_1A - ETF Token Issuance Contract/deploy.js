const hre = require("hardhat");

async function main() {
  const ETFTokenIssuance = await hre.ethers.getContractFactory("ETFTokenIssuance");
  const issuanceContract = await ETFTokenIssuance.deploy();
  await issuanceContract.deployed();
  console.log("ETF Token Issuance Contract deployed to:", issuanceContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

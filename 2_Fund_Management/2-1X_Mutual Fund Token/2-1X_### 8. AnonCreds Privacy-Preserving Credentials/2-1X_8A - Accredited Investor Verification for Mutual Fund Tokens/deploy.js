const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const MutualFundToken = await hre.ethers.getContractFactory("ERC20Token");
  const mutualFundToken = await MutualFundToken.deploy("Mutual Fund Token", "MFT", 18, 1000000);
  await mutualFundToken.deployed();

  console.log("Mutual Fund Token deployed to:", mutualFundToken.address);

  const AccreditedInvestorVerification = await hre.ethers.getContractFactory("AccreditedInvestorVerification");
  const accreditedInvestorVerification = await AccreditedInvestorVerification.deploy(mutualFundToken.address, deployer.address);

  await accreditedInvestorVerification.deployed();
  console.log("Accredited Investor Verification deployed to:", accreditedInvestorVerification.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

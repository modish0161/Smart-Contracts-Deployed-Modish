const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const WhitelistingBlacklistingMutualFund = await hre.ethers.getContractFactory("WhitelistingBlacklistingMutualFund");
  const mutualFundToken = await WhitelistingBlacklistingMutualFund.deploy(
    "Mutual Fund Whitelist Blacklist Token", // Token name
    "MFWBT",                                // Token symbol
    1000000 * 10 ** 18                      // Initial supply (1 million tokens)
  );

  await mutualFundToken.deployed();
  console.log("Whitelisting and Blacklisting Mutual Fund Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

async function main() {
    const WhitelistingBlacklistingContract = await ethers.getContractFactory("WhitelistingBlacklistingContract");
    const whitelistingBlacklistingContract = await WhitelistingBlacklistingContract.deploy("WhitelistBlacklist Security Token", "WBST", 18, 1000000);
    await whitelistingBlacklistingContract.deployed();
    console.log("WhitelistingBlacklistingContract deployed to:", whitelistingBlacklistingContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

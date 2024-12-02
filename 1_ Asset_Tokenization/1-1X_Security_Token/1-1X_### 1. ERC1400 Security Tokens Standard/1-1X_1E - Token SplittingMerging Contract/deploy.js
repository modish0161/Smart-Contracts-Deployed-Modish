async function main() {
    const TokenSplittingMergingContract = await ethers.getContractFactory("TokenSplittingMergingContract");
    const tokenSplittingMergingContract = await TokenSplittingMergingContract.deploy("SplitMerge Security Token", "SMST", 18, 1000000);
    await tokenSplittingMergingContract.deployed();
    console.log("TokenSplittingMergingContract deployed to:", tokenSplittingMergingContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

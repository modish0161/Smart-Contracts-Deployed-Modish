async function main() {
    const LockUpPeriodContract = await ethers.getContractFactory("LockUpPeriodContract");
    const lockUpPeriodContract = await LockUpPeriodContract.deploy("LockUp Security Token", "LST", 18, 1000000);
    await lockUpPeriodContract.deployed();
    console.log("LockUpPeriodContract deployed to:", lockUpPeriodContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

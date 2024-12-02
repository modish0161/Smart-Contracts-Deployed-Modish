const BasicAtomicSwap = artifacts.require("BasicAtomicSwap");

module.exports = function (deployer) {
  deployer.deploy(BasicAtomicSwap);
};

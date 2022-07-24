const { getNamedAccounts, deployments, chainId } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;

  log("Deploying......");
  const tokenLock = await deploy("TokenLock", {
    from: deployer,
    args: [],
    log: true,
  });
  log("==========Contract Deployed Successfully==========");
  log(`TokenLock deployed to ${tokenLock.address}`);

};


module.exports.tags = ["all", "lock"];

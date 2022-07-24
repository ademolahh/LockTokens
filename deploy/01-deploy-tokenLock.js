const { getNamedAccounts, deployments, chainId } = require("hardhat");
const { verify } = require("../utils/verify");

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

  if(chainId === 5){
    await verify(tokenLock.address)
  }
};


module.exports.tags = ["all", "lock"];

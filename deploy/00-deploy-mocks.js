const { getNamedAccounts, deployments, network } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;

  if (chainId === 31337) {
    await deploy("TestERC20", {
      from: deployer,
      args: [],
      log: true,
    });
    log("======ERC20 Deployed=========");

    await deploy("TestMyERC20", {
      from: deployer,
      args: [],
      log: true,
    });
    log("======ERC20 Deployed=========");

    await deploy("TestERC721", {
      from: deployer,
      args: [],
      log: true,
    });

    log("=========ERC721 DEPLOYED=========");

    await deploy("TestERC1155", {
      from: deployer,
      args: [],
      log: true,
    });
    log("======ERC1155 Deployed=========");
  }
};
module.exports.tags = ["all", "test"];

const { expect } = require("chai");
const { deployments, ethers, network } = require("hardhat");

describe("Time lock", () => {
  let tokenLock, erc20, erc721, erc1155, Oerc20;
  beforeEach(async () => {
    await deployments.fixture(["all"]);
    tokenLock = await ethers.getContract("TokenLock");
    erc20 = await ethers.getContract("TestERC20");
    erc721 = await ethers.getContract("TestERC721");
    erc1155 = await ethers.getContract("TestERC1155");
    Oerc20 = await ethers.getContract("TestMyERC20");
  });
  const token = (n) => {
    return ethers.utils.parseEther(n);
  };
  before(async () => {
    accounts = await ethers.getSigners();
    owner = accounts[0];
    depositor = accounts[1];
    // await erc20.transfer(depositor.address, token("1000"));
  });
  describe("ERC20", async () => {
    it("Deposite ERC20", async () => {
      await erc20.approve(tokenLock.address, token("100"));
      await Oerc20.approve(
        tokenLock.address,
        await Oerc20.balanceOf(owner.address)
      );
      await expect(
        tokenLock.depositeERC20(erc20.address, 101, 60)
      ).to.be.revertedWith("NotEnoughAllowance()");
      await tokenLock.depositeERC20(erc20.address, "2", 60);
      await tokenLock.depositeBulkERC20(
        [Oerc20.address, erc20.address],
        ["3", "4"],
        60
      );
    });
    it("Withdraw ERC20", async () => {
      // Infinite approval just for testing
      await Oerc20.approve(
        tokenLock.address,
        await Oerc20.balanceOf(owner.address)
      );
      await erc20.approve(
        tokenLock.address,
        await erc20.balanceOf(owner.address)
      );
      await tokenLock.depositeERC20(erc20.address, 2, 60);
      await expect(
        tokenLock.withdrawErc20(erc20.address, 3)
      ).to.be.revertedWith("notTime()");
      await network.provider.send("evm_increaseTime", [60]);
      await network.provider.request({ method: "evm_mine", params: [] });
      await tokenLock.withdrawErc20(erc20.address, 1);
      await tokenLock.withdrawErc20(erc20.address, 1);
      await tokenLock.depositeBulkERC20(
        [Oerc20.address, erc20.address],
        [3, 4],
        60
      );
      await network.provider.send("evm_increaseTime", [60]);
      await network.provider.request({ method: "evm_mine", params: [] });
      await tokenLock.withdrawErc20(Oerc20.address, 1);
      await expect(
        tokenLock.erc20BulkWithdrawal([Oerc20.address, erc20.address], [3, 4])
      ).to.be.revertedWith("insufficientBalance()");
      await tokenLock.erc20BulkWithdrawal(
        [Oerc20.address, erc20.address],
        [2, 4]
      );
    });
  });
  describe("ERC721", async () => {
    it("Deposite", async () => {
      await expect(
        tokenLock.depositeERC721(erc721.address, 4, 60)
      ).to.be.revertedWith("ContractNotApproved()");
      await erc721.setApprovalForAll(tokenLock.address, true);
      await tokenLock.depositeERC721(erc721.address, 4, 60);
      await expect(
        tokenLock.withdrawERC721(erc721.address, 1)
      ).to.be.revertedWith("notYours()");
      await tokenLock.depositeBulkERC721(erc721.address, [1, 2, 3], 60);
    });
    it("Withdraw", async () => {
      await erc721.setApprovalForAll(tokenLock.address, true);
      await tokenLock.depositeERC721(erc721.address, 4, 60);
      await expect(
        tokenLock.withdrawERC721(erc721.address, 1)
      ).to.be.revertedWith("notYours()");
      await tokenLock.depositeBulkERC721(erc721.address, [1, 2, 3], 60);
      await expect(
        tokenLock.bulkWithdrawERC721(erc721.address, [1, 2, 3, 4])
      ).to.be.revertedWith("notTime()");
      await network.provider.send("evm_increaseTime", [65]);
      await network.provider.request({ method: "evm_mine", params: [] });
      await expect(
        tokenLock.bulkWithdrawERC721(erc721.address, [])
      ).to.be.revertedWith("NoTokenIdSelected()");
      await tokenLock.bulkWithdrawERC721(erc721.address, [1, 2, 3, 4]);
      await erc721.setApprovalForAll(tokenLock.address, false);
    });
  });
  describe("ERC1155", () => {
    it("Deposite", async () => {
      await expect(
        tokenLock.depositeERC1155(erc1155.address, 1, 2, 60)
      ).to.be.revertedWith("ContractNotApproved()");
      await erc1155.setApprovalForAll(tokenLock.address, true);
      await expect(
        tokenLock.depositeERC1155(erc1155.address, 1, 2, 0)
      ).to.be.revertedWith("LockPeriodCannotBeZero()");
      await tokenLock.depositeERC1155(erc1155.address, 1, 2, 60);
      await expect(
        tokenLock.depositeBulkERC11155(erc1155.address, [2, 3], [1], 60)
      ).to.be.revertedWith("lengthsNotEqual()");
      await tokenLock.depositeBulkERC11155(erc1155.address, [2, 3], [1, 2], 60);
    });
    it("Withdraw", async () => {
      await erc1155.setApprovalForAll(tokenLock.address, true);
      await tokenLock.depositeERC1155(erc1155.address, 1, 2, 60);
      await expect(
        tokenLock.withdrawERC1155(erc1155.address, 1, 1)
      ).to.be.revertedWith("notTime()");
      await network.provider.send("evm_increaseTime", [65]);
      await network.provider.request({ method: "evm_mine", params: [] });
      await expect(
        tokenLock.withdrawERC1155(erc1155.address, 1, 3)
      ).to.be.revertedWith("insufficientBalance()");
      await tokenLock.withdrawERC1155(erc1155.address, 1, 2);
      await tokenLock.depositeBulkERC11155(erc1155.address, [2, 3], [1, 2], 60);
      await network.provider.send("evm_increaseTime", [65]);
      await network.provider.request({ method: "evm_mine", params: [] });
      await tokenLock.erc1155BulkWithdrawal(erc1155.address, [2, 3], [1, 1]);
    });
  });
});

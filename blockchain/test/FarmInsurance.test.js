import hre from "hardhat";
import { expect } from "chai";

describe("FarmInsurance", () => {
  let contract, owner, oracle, farmer, ethers;

  beforeEach(async () => {
    const connection = await hre.network.connect();
    ethers = connection.ethers;
    [owner, oracle, farmer] = await ethers.getSigners();
    const F = await ethers.getContractFactory("FarmInsurance");
    contract = await F.deploy(oracle.address);
  });

  it("funds pool", async () => {
    await contract.fundPool({ value: ethers.parseEther('1.0') });
    expect(await contract.getPoolBalance()).to.equal(ethers.parseEther('1.0'));
  });

  it("pays 100% — genuine outbreak", async () => {
    await contract.fundPool({ value: ethers.parseEther('2.0') });
    await contract.connect(oracle).registerFarmer("f1", farmer.address, ethers.parseEther("1.0"));
    const before = await ethers.provider.getBalance(farmer.address);
    await contract.connect(oracle).triggerPayout("f1", 100, "test");
    expect(await ethers.provider.getBalance(farmer.address) - before).to.equal(ethers.parseEther('1.0'));
  });

  it("pays 65% — fraud-adjusted", async () => {
    await contract.fundPool({ value: ethers.parseEther('2.0') });
    await contract.connect(oracle).registerFarmer("f2", farmer.address, ethers.parseEther("1.0"));
    const before = await ethers.provider.getBalance(farmer.address);
    await contract.connect(oracle).triggerPayout("f2", 65, "fraud");
    expect(await ethers.provider.getBalance(farmer.address) - before).to.equal(ethers.parseEther('0.65'));
  });

  it("blocks non-oracle", async () => {
    try {
      await contract.connect(owner).triggerPayout("f1", 100, "x");
      expect.fail("Should have reverted");
    } catch (e) {
      expect(e.message).to.include("Not oracle");
    }
  });
});

import hre from "hardhat";
import { getAddress } from "ethers";
import * as dotenv from "dotenv";
dotenv.config();

async function main() {
  const connection = await hre.network.connect("sepolia");
  const ethers = connection.ethers;
  const [deployer] = await ethers.getSigners();
  const contract = await ethers.getContractAt("FarmInsurance", getAddress(process.env.CONTRACT_ADDRESS));
  const tx = await contract.fundPool({ value: ethers.parseEther("0.05") });
  await tx.wait();
  console.log("Pool funded! tx:", tx.hash);
  console.log("Pool balance:", (await contract.getPoolBalance()).toString());
}

main().catch(e => { console.error(e); process.exit(1); });

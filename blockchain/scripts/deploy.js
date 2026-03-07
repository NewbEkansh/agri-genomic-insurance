import hre from "hardhat";
import { getAddress } from "ethers";
import * as dotenv from "dotenv";
dotenv.config();

async function main() {
  const connection = await hre.network.connect("sepolia");
  const ethers = connection.ethers;
  const [deployer] = await ethers.getSigners();
  console.log("Deploying from:", deployer.address);

  const oracle = getAddress(process.env.ORACLE_ADDRESS || deployer.address);
  console.log("Oracle address:", oracle);

  const F = await ethers.getContractFactory("FarmInsurance");
  const contract = await F.deploy(oracle);
  await contract.waitForDeployment();

  const addr = await contract.getAddress();
  console.log("Contract deployed to:", addr);
  console.log("Etherscan: https://sepolia.etherscan.io/address/" + addr);
  console.log("Add to .env: CONTRACT_ADDRESS=" + addr);
}

main().catch(e => { console.error(e); process.exit(1); });

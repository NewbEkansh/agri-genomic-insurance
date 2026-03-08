import hardhatEthers from "@nomicfoundation/hardhat-ethers";
import hardhatMocha from "@nomicfoundation/hardhat-mocha";
import * as dotenv from "dotenv";
dotenv.config();

const privateKey = process.env.ORACLE_PRIVATE_KEY.startsWith("0x")
  ? process.env.ORACLE_PRIVATE_KEY
  : `0x${process.env.ORACLE_PRIVATE_KEY}`;

export default {
  plugins: [hardhatEthers, hardhatMocha],
  solidity: "0.8.20",
  networks: {
    sepolia: {
      type: "http",
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [privateKey],
    },
  },
  paths: {
    tests: {
      mocha: "./test",
    },
  },
};

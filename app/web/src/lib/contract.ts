import { ethers } from 'ethers';

const CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS ?? '0x722bEC25d44dEED2F720ebee6415854A039DDA9C';
const RPC_URL = process.env.NEXT_PUBLIC_SEPOLIA_RPC_URL ?? 'https://eth-sepolia.g.alchemy.com/v2/demo';

const ABI = [
  'function getPoolBalance() external view returns (uint256)',
  'function getFarmer(string calldata farmId) external view returns (tuple(address wallet, uint256 insuredAmountWei, bool active, uint256 registeredAt))',
];

let contract: ethers.Contract | null = null;

function getContract(): ethers.Contract {
  if (!contract) {
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, provider);
  }
  return contract;
}

export async function getPoolBalanceEth(): Promise<string> {
  try {
    const bal: bigint = await getContract().getPoolBalance();
    return ethers.formatEther(bal);
  } catch { return '—'; }
}

export const ETHERSCAN_TX = (hash: string) => `https://sepolia.etherscan.io/tx/${hash}`;
export const ETHERSCAN_CONTRACT = () => `https://sepolia.etherscan.io/address/${CONTRACT_ADDRESS}`;

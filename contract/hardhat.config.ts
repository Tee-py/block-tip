import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import 'hardhat-abi-exporter';
import 'dotenv/config';

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.4',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  abiExporter: {
    runOnCompile: true,
    only: ['SocialDonation'],
    path: './abis',
    format: 'json',
    clear: true,
  },
  networks:
    process.env.PRIVATE_KEY
      ? {
          hardhat: {
            allowUnlimitedContractSize: true,
          },
          eth: {
            url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY!}`,
            chainId: 1,
            accounts: [process.env.PRIVATE_KEY!],
          },
          baseSepolia: {
            url: 'https://sepolia.base.org',
            chainId: 84532,
            accounts: [process.env.PRIVATE_KEY!],
          },
        }
      : undefined,
  etherscan:
    process.env.BASE_SEPOLIA_EXPLORER_API_KEY
      ? {
          customChains: [
            {
              network: 'baseSepolia',
              chainId: 84532,
              urls: {
                apiURL: 'https://sepolia.basescan.org/api',
                browserURL: 'https://sepolia.basescan.org/',
              },
            },
          ],
          apiKey: {
            baseSepolia: process.env.BASE_SEPOLIA_EXPLORER_API_KEY!,
          },
        }
      : undefined,
  sourcify: {
    enabled: true,
  },
};

export default config;

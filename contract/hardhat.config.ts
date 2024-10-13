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
};

export default config;

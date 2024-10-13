// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const BlockTipModule = buildModule("BlockTipModule", (m) => {
  const reclaimAddress = "0xF90085f5Fd1a3bEb8678623409b3811eCeC5f6A5";

  const SocialDonation = m.contract("SocialDonation", [reclaimAddress]);

  return { SocialDonation };
});

export default BlockTipModule;

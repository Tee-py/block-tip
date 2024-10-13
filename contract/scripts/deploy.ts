import hre from "hardhat";

async function deploy() {
    const reclaimAddress = "0xF90085f5Fd1a3bEb8678623409b3811eCeC5f6A5";

    const SocialDonation = await hre.ethers.getContractFactory("SocialDonation");
    const donation = await SocialDonation.deploy(reclaimAddress);

    console.log(`Social Donation Contract Deployed to: ${await donation.getAddress()}`)
}

deploy().catch(console.error)
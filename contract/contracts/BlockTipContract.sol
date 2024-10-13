// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@reclaimprotocol/verifier-solidity-sdk/contracts/Reclaim.sol";
import "@reclaimprotocol/verifier-solidity-sdk/contracts/Claims.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SocialDonation {
    enum Platform { Twitter, GitHub }
    struct Donation {
        address donor;
        string fromId;
        string toId;
        Platform platform;
        address token;
        uint256 amount;
        bool claimed;
    }
    
    address public reclaimAddress;
    Donation[] public donations;

    event DonationCreated(
        uint256 indexed donationId,
        address indexed donor,
        string fromId,
        string toId,
        Platform platform,
        address token,
        uint256 amount,
        string note
    );

    event DonationClaimed(
        uint256 indexed donationId,
        address indexed beneficiary
    );

    constructor(address _reclaimAddress) {
        reclaimAddress = _reclaimAddress;
    }

    function donate(
        string memory fromId,
        string memory toId,
        Platform platform,
        address token,
        uint256 amount,
        string memory note
    ) external payable {
        require(bytes(fromId).length > 0, "Donor ID is required");
        require(bytes(toId).length > 0, "Beneficiary ID is required");

        if (token == address(0)) {
            // Donation in native currency (e.g., ETH)
            require(msg.value == amount, "Incorrect ETH amount");
        } else {
            // Donation in ERC-20 token
            require(msg.value == 0, "ETH not accepted for token donations");
            require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        }

        // Record the donation
        donations.push(Donation({
            donor: msg.sender,
            fromId: fromId,
            toId: toId,
            platform: platform,
            token: token,
            amount: amount,
            claimed: false
        }));

        uint256 donationId = donations.length;
        emit DonationCreated(donationId, msg.sender, fromId, toId, platform, token, amount, note);
    }

    function claim(uint256 donationId, Reclaim.Proof memory proof) external {
        Donation storage donation = donations[donationId - 1];
        require(!donation.claimed, "Donation already claimed");
        Reclaim(reclaimAddress).verifyProof(proof);
        string memory socialId = Claims.extractFieldFromContext(proof.claimInfo.context, '"SocialId":"');
        require(keccak256(bytes(socialId)) == keccak256(bytes(donation.toId)), "Only the beneficiary can claim");
        donation.claimed = true;
        if (donation.token == address(0)) {
            payable(msg.sender).transfer(donation.amount);
        } else {
            require(IERC20(donation.token).transfer(msg.sender, donation.amount), "Token transfer failed");
        }
        emit DonationClaimed(donationId, msg.sender);
    }

    function getDonationDetails(uint256 donationId) external view returns (
        address donor,
        string memory fromId,
        string memory toId,
        Platform platform,
        address token,
        uint256 amount,
        bool claimed
    ) {
        Donation memory donation = donations[donationId - 1];
        return (
            donation.donor,
            donation.fromId,
            donation.toId,
            donation.platform,
            donation.token,
            donation.amount,
            donation.claimed
        );
    }
}
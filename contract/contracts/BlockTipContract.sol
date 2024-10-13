// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@reclaimprotocol/verifier-solidity-sdk/contracts/Reclaim.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SocialDonation {
    struct Donation {
        address donor;
        string fromId;
        string toId;
        string platform;
        address token;
        uint256 amount;
        bool claimed;
    }
    
    address public reclaimAddress;
    address admin;
    mapping(string => bool) public isSupportedPlatform;
    Donation[] public donations;

    event DonationCreated(
        uint256 indexed donationId,
        address indexed donor,
        string fromId,
        string toId,
        string platform,
        address token,
        uint256 amount,
        string note
    );

    event DonationClaimed(
        uint256 indexed donationId,
        address indexed beneficiary
    );

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not permitted");
        _;
    }

    constructor(address _reclaimAddress, string[] memory _supportedPlatforms) {
        reclaimAddress = _reclaimAddress;
        admin = msg.sender;

        for (uint i = 0; i < _supportedPlatforms.length; i++) {
            isSupportedPlatform[_supportedPlatforms[i]] = true;
        }
    }

    function donate(
        string memory fromId,
        string memory toId,
        string memory platform,
        address token,
        uint256 amount,
        string memory note
    ) external payable {
        require(bytes(fromId).length > 0, "Donor ID is required");
        require(bytes(toId).length > 0, "Beneficiary ID is required");
        require(isSupportedPlatform[platform], "Unsupported social platform");

        if (token == address(0)) {
            require(msg.value == amount, "Incorrect ETH amount");
        } else {
            require(msg.value == 0, "ETH not accepted for token donations");
            require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        }
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
        string memory socialId = extractFieldFromContext(proof.claimInfo.context, '"SocialId":"');
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
        string memory platform,
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

    function addPlatform(string memory _platform) public onlyAdmin {
        isSupportedPlatform[_platform] = true;
    }

    function extractFieldFromContext(
        string memory data,
        string memory target
    ) public pure returns (string memory) {
        bytes memory dataBytes = bytes(data);
        bytes memory targetBytes = bytes(target);

        require(
            dataBytes.length >= targetBytes.length,
            "target is longer than data"
        );
        uint start = 0;
        bool foundStart = false;
        // Find start of "contextMessage":"

        for (uint i = 0; i <= dataBytes.length - targetBytes.length; i++) {
            bool isMatch = true;

            for (uint j = 0; j < targetBytes.length && isMatch; j++) {
                if (dataBytes[i + j] != targetBytes[j]) {
                    isMatch = false;
                }
            }

            if (isMatch) {
                start = i + targetBytes.length; // Move start to the end of "contextMessage":"
                foundStart = true;
                break;
            }
        }

        if (!foundStart) {
            return ""; // Malformed or missing message
        }

        // Find the end of the message, assuming it ends with a quote not preceded by a backslash.
        // The function does not need to handle escaped backslashes specifically because
        // it only looks for the first unescaped quote to mark the end of the field value.
        // Escaped quotes (preceded by a backslash) are naturally ignored in this logic.
        uint end = start;
        while (
            end < dataBytes.length &&
            !(dataBytes[end] == '"' && dataBytes[end - 1] != "\\")
        ) {
            end++;
        }

        // if the end is not found, return an empty string because of malformed or missing message
        if (
            end <= start ||
            !(dataBytes[end] == '"' && dataBytes[end - 1] != "\\")
        ) {
            return ""; // Malformed or missing message
        }

        bytes memory contextMessage = new bytes(end - start);
        for (uint i = start; i < end; i++) {
            contextMessage[i - start] = dataBytes[i];
        }
        return string(contextMessage);
    }
}
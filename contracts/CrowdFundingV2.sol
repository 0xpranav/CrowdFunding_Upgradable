// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./CrowdFunding.sol";

/// @title Version two of 'CrowdFunding' contract
/// @author Pranav Garg
/// @notice It Inherit the crowdfunding contract so possess all the earlier defined functions in it
contract CrowdFundingV2 is CrowdFunding {
    ///@dev added a test function to check for upgradation
    function testUpgrade() public pure returns (string memory) {
        return "upgraded";
    }
}
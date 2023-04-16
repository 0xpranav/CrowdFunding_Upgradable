// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/// @dev interface for Gcoin token, only added required functions from safeERC20
interface IGcoin {
    
    ///@dev transfer tokens directly from contract address to recipient
    function safeTransfer(address recipient, uint amount) external returns (bool);

    /// @dev this function requires approval to transfer tokens on their behalf to recipient address
    ///@dev approval limit set must be more than amount provided in it
    function safeTransferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

}


/// @title Crowdfunding contract is platform tool to create & claim tokens based on goal complition
/// @author  Pranav Garg
/// @notice It is an upgradable contract so it will not uses constructor
contract CrowdFunding is  Initializable,UUPSUpgradeable,OwnableUpgradeable{

/// @notice IGcoin interface uses SafeERC20 extension, It ensure the transfer/transferFrom function works correctly, even if they not return anything
using SafeERC20 for IGcoin;

// It keeps the campaign records
    struct Campaign {
        address initiator;
        uint goal;
        uint pledged;
        uint startTime;
        uint endTime;
        bool claimed;
    }

// _IGcoin - is an instance of IGcoin interface
    IGcoin public _IGcoin;
    uint public count;
    uint public maxDuration;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public pledgedAmount;

///@dev emit the campaign event information
    event Launch(
        uint id,
        address indexed initiator,
        uint goal,
        uint32 startTime,
        uint32 endTime
    );
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint id, address indexed caller, uint amount);

/// @dev initialize in use in place of constructor, it uses initializer as modifier which tells the evm to run it first after upgrade
/// @param GCoin_CONTRACT_ADDRESS- Gcoin contract address to access its function 
/// @param _maxDuration- maximum duraition a campaign can last
    function initialize(address GCoin_CONTRACT_ADDRESS, uint _maxDuration) public initializer {
        __Ownable_init_unchained();
         _IGcoin = IGcoin(GCoin_CONTRACT_ADDRESS);
        maxDuration = _maxDuration;
    }


/// @param newImplementation- new address of implementation contract with modifier onlyOwner, UUPS proxy pattern     
   function _authorizeUpgrade(address newImplementation) internal override onlyOwner {

    }

///@dev launch a new campaign for crowdfunding
    function launch(uint _goal, uint32 _startTime, uint32 _endTime) external {
        require(_startTime >= block.timestamp,"Start time is less than current Block Timestamp");
        require(_endTime > _startTime,"End time is less than Start time");
        require(_endTime <= block.timestamp + maxDuration, "End time exceeds the maximum Duration");

        count += 1;
        campaigns[count] = Campaign({
            initiator: msg.sender,
            goal: _goal,
            pledged: 0,
            startTime: _startTime,
            endTime: _endTime,
            claimed: false
        });

        emit Launch(count,msg.sender,_goal,_startTime,_endTime);
    }

///@dev cancel campaign
    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(campaign.initiator == msg.sender, "You did not create this Campaign");
        require(block.timestamp < campaign.startTime, "Campaign has already started");

        delete campaigns[_id];
        emit Cancel(_id);
    }

    

//pledge the tokens for campaign
    function pledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startTime, "Campaign has not Started yet");
        require(block.timestamp <= campaign.endTime, "Campaign has already ended");
         campaign.pledged += _amount;
            pledgedAmount[_id][msg.sender] += _amount;
            _IGcoin.safeTransferFrom(msg.sender,address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
       
       
    }

// unpledge the tokens from campaign    
    function unPledge(uint _id,uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startTime, "Campaign has not Started yet");
        require(block.timestamp <= campaign.endTime, "Campaign has already ended");
        require(pledgedAmount[_id][msg.sender] >= _amount,"You do not have enough _IGcoins Pledged to withraw");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        _IGcoin.safeTransfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);
    }

// claim the tokens after successfully compltion of campaign
    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(campaign.initiator == msg.sender, "You did not create this Campaign");
        require(block.timestamp > campaign.endTime, "Campaign has not ended");
        require(campaign.pledged >= campaign.goal, "Campaign did not succed");
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;
        _IGcoin.safeTransfer(campaign.initiator, campaign.pledged);

        emit Claim(_id);
    }

// refund the tokens incase of campaign failure
    function refund(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(block.timestamp > campaign.endTime, "not ended");
        require(campaign.pledged < campaign.goal, "You cannot Withdraw, Campaign has succeeded");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        _IGcoin.safeTransfer(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);
    }

    
}

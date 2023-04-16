// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Gcoin is ERC20, Ownable {

///@dev maintain the status of whitlisted address & address which minted the token
    struct mintDetails {
        bool mintOnce;
        bool whitelisted;
    }
    
// constructor to initilize the name & symbol of token
    constructor() ERC20("Gcoin", "GC") {

    }

// emit the token mint information
    event tokenMintedBy(address _addrs, uint8 _amount);

// map the address to status
    mapping(address => mintDetails) whitelistedAddresses;

/// @dev add the user to whitelist for token mint
    function addUser(address _addressToWhitelist) public onlyOwner {
        whitelistedAddresses[_addressToWhitelist].whitelisted = true;
    }


/// @dev returns the status of an address in whitelist
    function verifyUser(address _address) public view returns(bool) {
        bool userIsWhitelisted = whitelistedAddresses[_address].whitelisted;
        return userIsWhitelisted;
    }

/// @dev mint the token if it is in whitelist, amount is less than 100 tokens
///@dev change the status of account to mintOnce so it can't mint more tokens
    function mint(address to, uint8 amount) public {
        require(verifyUser(to),"This address is not whitelisted.");
         require(!whitelistedAddresses[to].mintOnce,"This address already mint tokens.");
        require(amount <= 100,"Please Enter amount less than or equal to 100");
        _mint(to,amount* 10 ** uint(decimals()));
        emit tokenMintedBy(to, amount);
        whitelistedAddresses[to].mintOnce = true;     
    }
    
}
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DiceRoller is Ownable {

    // Dice Roll will consist of a dice type and its result.
    struct DiceRoll {
        uint diceType;
        uint result;
    }

    // users can have multiple dice rolls
    mapping (address => DiceRoll[]) userRollHistory;

    // keep list of user addresses for fun/stats
    // can iterate over them later.
    address[] internal userAddresses;

    uint256 private seed;

    // Emit this when the roll function is called.
    // Used by dapp to display results.
    event DiceWasRolled(address roller, uint result);

    constructor() {
        // set the iniitial seed
        seed = getRando();
    }

    function randomCheck() public onlyOwner view returns (uint256) {
        return getRando();
    }

    /*
        Generate a new seed for the next user when they roll
    */
    function getRando() internal view returns (uint256) {
        // console.log("block.difficulty: %d", block.timestamp + block.difficulty);
        uint256 tempSeed = (block.timestamp + block.difficulty) % 100;
        console.log("Random number generated: %d", tempSeed);
        return tempSeed;
    }
    
    function kill() external onlyOwner {
        require(isOwner(), "Only the owner can kill this contract");
        selfdestruct( payable(owner()) );
    }

    function isOwner() internal view virtual returns (bool) {
        return msg.sender == owner();
    }

    // generates a new dice roll for the address at msg.sender
    // emit an event with the rolled result.
    function roll() public {
        // generate random concept
        DiceRoll memory diceRoll = DiceRoll(1,6);
        userRollHistory[msg.sender].push(diceRoll);
        userAddresses.push(msg.sender);
        emit DiceWasRolled(msg.sender, 6);

        seed = getRando();
    }

    // returns historic data for specific address/user
    function getUserRolls(address _address) external view returns (DiceRoll[] memory) {
        return userRollHistory[_address];
    }

    // only allow the contract owner (me) to access this.
    function getAllUsers() external view returns (address[] memory) {
        return userAddresses;
    }

    // gotta know how many folks have used this contract
    function countUsers() view public returns (uint) {
        return userAddresses.length;
    }

    // gotta know how many times a specific user rolled.
    function countUserRolls(address _address) view public returns (uint) {
        return userRollHistory[_address].length;
    }
}

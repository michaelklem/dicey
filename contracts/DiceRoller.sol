//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DiceRoller is Ownable {

    // Dice Roll will consist of a dice type and its result.
    struct DiceRoll {
        uint numberOfDice; // 1 = roll once, 4 = roll for die
        uint sizeOfDie; // 6 = 6 sided die, 20 = 20 sided die
        int adjustment; //+/- 4
        int result;
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

    constructor() {}


    /*
        Generate a new seed for the next user when they roll
    */
    function getRando(uint _dieSize) internal view returns (uint256) {
        // console.log("block.difficulty: %d", block.timestamp + block.difficulty);
        uint256 tempSeed = ((block.timestamp + block.difficulty) % _dieSize) + 1;
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

    /*
        Called by app when it handles the actual randomization in JS because that 
        is so much easier and doesn't cost anything. We just use this to store the 
        result of the roll.


        @result can be negative if you have a low enough dice roll and larger negative adjustment
        Rolled 3 with -4 adjustment.
    */
    function wasRolled(uint _numberOfDice, uint _dieSize, int _adjustment, int result) public {
        DiceRoll memory diceRoll = DiceRoll(_numberOfDice, _dieSize, _adjustment, result);
        userRollHistory[msg.sender].push(diceRoll);
        userAddresses.push(msg.sender);
    }
    
    /*

        generates a new dice roll for the address at msg.sender
        emit an event with the rolled result.

        Trying to implement roll20's syntax
        <number of dice to roll>d<dice type [4 | 6 | 20 | 100] +/- <adjustment>
        2d20+5
    */
    function roll(uint _numberOfDice, uint _dieSize, int _adjustment) public {
        /*      
        seed = 0;
        while (_numberOfDice > 0) {
            seed += getRando(_dieSize);
            console.log('seed: %d',seed);
            --_numberOfDice;
        }
        DiceRoll memory diceRoll = DiceRoll(1,1, 1,6);
        userRollHistory[msg.sender].push(diceRoll);
        userAddresses.push(msg.sender);
        emit DiceWasRolled(msg.sender, 6);
        */
    }

    // pass 1. 20, 5 to represent 1d20+5
    // pass 1. 6 to represent 1d6
    // function parseRollType(string memory _rollType) internal view {
    // function parseRollType(string memory _numberOfDice, string memory _dieSize, string memory _adjustment) internal view {
    //     // require(IsEmptyString(_rollType), "Expected a non-empty roll type");

    // }


    // function IsEmptyString(string memory str) internal view returns(bool) {        
    //     bytes memory tempEmptyStringTest = bytes(str); // Uses memory
    //     console.log("tempEmptyStringTest.length: %d",tempEmptyStringTest.length);
    // //   console.log("%s waved %d times", msg.sender, totalWaveByAddress[msg.sender]);

    //     return tempEmptyStringTest.length > 0;
    // }

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

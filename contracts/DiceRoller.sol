// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// to do
// verify I can return more data in the DiceLanded event
// can a roller have multiple roll histories
// userRollHistory can that work?

/*
    https://docs.chain.link/docs/vrf-contracts/
    Testnet LINK are available from https://faucets.chain.link/kovan
    Kovan deploy values:
    const contract = await contractFactory.deploy(
        0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRFCOORDINATOR
        0xa36085F69e2889c224210F603D836748e7dC0088, // LINK
        0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4,  // KEYHASH
        100000000000000000 // FEE
    ); 
*/
contract DiceRoller is VRFConsumerBase, Ownable {

    bytes32 private _chainLinkKeyHash;
    uint256 private _chainlinkVRFFee;
    int private constant ROLL_IN_PROGRESS = 42;

    struct DiceRollee {
        address rollee;
        uint256 randomness; /// Stored to help verify/debug results
        uint numberOfDice; /// 1 = roll once, 4 = roll four die
        uint sizeOfDie; // 6 = 6 sided die, 20 = 20 sided die
        int adjustment; /// Can be a positive or negative value
        int result; /// result of all die rolls and adjustment
        uint timestamp; /// when we rolled
        uint[] rolledValues; /// array of individual rolls
    }

    /**
    * Mapping between the requestID (returned when a request is made), 
    * and the address of the roller. This is so the contract can keep track of 
    * who to assign the result to when it comes back.
    */
    mapping(bytes32 => address) private _rollers;

    /// stores the roller and the result of the dice roll.
    mapping(address => DiceRollee) private _results;

    // Dice Roll will consist of a dice type and its result.
    struct DiceRoll {
        uint numberOfDice; // 1 = roll once, 4 = roll for die
        uint sizeOfDie; // 6 = 6 sided die, 20 = 20 sided die
        int adjustment; //+/- 4
        int result;
    }

    /// users can have multiple dice rolls
    mapping (address => DiceRoll[]) userRollHistory;

    /// keep list of user addresses for fun/stats
    /// can iterate over them later.
    address[] internal userAddresses;

    /// Emit this when the roll function is called.
    event DiceRolled(bytes32 indexed requestId, address indexed roller);

    /// Emitted when fulfillRandomness is called by Chainlink VRF to provide the random value.
    event DiceLanded(bytes32 indexed requestId, address indexed roller, uint[] rolledvalues, int adjustment, int result);


    constructor(address vrfCoordinator, address link, bytes32 keyHash, uint256 fee)
        VRFConsumerBase(vrfCoordinator, link)
    {
        _chainLinkKeyHash = keyHash;
        _chainlinkVRFFee = fee;
    }

    /**
    * When the contract is killed, make sure to return all unspent tokens back to my wallet.
    */
    function kill() external onlyOwner {
        LINK.transfer(owner(), getLINKBalance());
        selfdestruct( payable(owner()) );
    }

    /**
    * Called by the front end if user wants to use the front end to 
    * generate the random values. We just use this to store the result of the roll on the blockchain.
    *
    * @param numberOfDice how many dice are rolled
    * @param dieSize the type of die rolled (4 = 4 sided, 6 = six sided, etc.)
    * @param adjustment the modifier to add after all die have been rolled. Can be negative.
    * @param result can be negative if you have a low enough dice roll and larger negative adjustment.
    * Example, rolled 2 4 sided die with -4 adjustment.
    */
    function wasRolled(uint numberOfDice, uint dieSize, int adjustment, int result) public {
        DiceRollee memory diceRollee = DiceRollee(
                msg.sender, 0, numberOfDice, 
                dieSize, adjustment, result, 
                block.timestamp,
                new uint[](numberOfDice)
                );
        _results[msg.sender] = diceRollee;

        DiceRoll memory diceRoll = DiceRoll(numberOfDice, dieSize, adjustment, result);
        userRollHistory[msg.sender].push(diceRoll);
        userAddresses.push(msg.sender);
    }
    

    /**
     * @notice Requests randomness from Chainlink.
     *
     * @param roller address of the roller
     * @param numberOfDice how many dice are rolled
     * @param dieSize the type of die rolled (4 = 4 sided, 6 = six sided, etc.)
     * @param adjustment the modifier to add after all die have been rolled. Can be negative.
     */
    function rollDice(
        address roller, 
        uint numberOfDice, 
        uint dieSize, 
        int adjustment) 
        public 
        returns (bytes32 requestId) 
    {
        /// checking LINK balance to make sure we can call the Chainlink VRF.
        require(LINK.balanceOf(address(this)) >= _chainlinkVRFFee, "Not enough LINK to pay fee");

        userAddresses.push(msg.sender);

        /// Call to Chainlink VRF for randomness
        requestId = requestRandomness(_chainLinkKeyHash, _chainlinkVRFFee);
        _rollers[requestId] = roller;

        DiceRollee memory diceRollee = DiceRollee(
                roller, 0, numberOfDice, 
                dieSize, adjustment, ROLL_IN_PROGRESS, 
                block.timestamp,
                new uint[](numberOfDice)
                );
        _results[roller] = diceRollee;
        emit DiceRolled(requestId, roller);
    }


    /**
     * @notice Uses psuedo randomness based on blockchain data. This function is used to 
     * compare speed of getting some sort of randomness straight from the blockchain 
     * instead of waiting for Chainlink VRF to return a random value.
     *
     * @param roller address of the roller
     * @param numberOfDice how many dice are rolled
     * @param dieSize the type of die rolled (4 = 4 sided, 6 = six sided, etc.)
     * @param adjustment the modifier to add after all die have been rolled. Can be negative.
     */
    function rollDiceFast(
        address roller, 
        uint numberOfDice, 
        uint dieSize, 
        int adjustment) 
        public 
        returns (bytes32 requestId) 
    {
        /// Simple hacky way to generate a requestId.
        requestId = keccak256(abi.encodePacked(_chainLinkKeyHash, block.timestamp));
        _rollers[requestId] = roller;
        DiceRollee memory diceRollee = DiceRollee(
                roller, 0, numberOfDice, 
                dieSize, adjustment, ROLL_IN_PROGRESS, 
                block.timestamp,
                new uint[](numberOfDice)
                );
        _results[roller] = diceRollee;
        emit DiceRolled(requestId, roller);
        uint256 randomness = (block.timestamp + block.difficulty);
        fulfillRandomness(requestId, randomness);
    }

    /// returns historic data for specific address/user
    // function getUserRolls(address _address) public view returns (DiceRoll[] memory) {
    //     return userRollHistory[_address];
    // }

    /// only allow the contract owner (me) to access this.
    // function getAllUsers() public view returns (address[] memory) {
    //     return userAddresses;
    // }

    /// gotta know how many folks have used this contract
    // function countUsers() view public returns (uint) {
    //     return userAddresses.length;
    // }

    /// gotta know how many times a specific user rolled.
    // function countUserRolls(address _address) view public returns (uint) {
    //     return userRollHistory[_address].length;
    // }

    function getRoller(address _roller) view public returns (DiceRollee memory) {
        return _results[_roller];
    }

    function getBalance() view public returns (uint256) {
        return address(this).balance;
    }

    // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
    // https://medium.com/coinmonks/get-token-balance-for-any-eth-address-by-using-smart-contracts-in-js-b603fef2061c
    // returns the amount of LINK tokens this contract has.
    function getLINKBalance() view public onlyOwner returns (uint256) {
       return LINK.balanceOf(address(this));
    }

    /**
     * @notice Callback function used by VRF Coordinator to return the random number
     * to this contract.
     *
     * This is the core function where we try to generate random values from a single
     * random value provided. For each die to roll, we use the passed inrandom value
     * perform some calculation on it to generate a new "random" value that we then
     * perform the mod on. Goal is if you are rolling x 10 sided die, each roll 
     * generates a different value.
     *
     * @param requestId bytes32
     * @param randomness The random result returned by the oracle
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        /// Associate the random value with the roller based on requestId.
        DiceRollee storage rollee = _results[_rollers[requestId]];
        delete rollee.rolledValues;
        rollee.randomness = randomness;

        uint counter; /// Tracks how many die have been rolled.
        int calculatedValue;
        
        /// Using these values to manipulate the random value on each die roll.
        // 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
        // 1010101010101010
        uint someValue1 = 77194726158210796949047323339125271902179989777093709359638389338608753093290;

        // 0x55555555555555555555555555555555555555555555555555555555555555555
        // 0101010101
        uint someValue2 = 38597363079105398474523661669562635951089994888546854679819194669304376546645;

        /// iterate over each die to be rolled and calc the value based on a sort of randomness.
        while (counter < rollee.numberOfDice) {
            uint curValue;
            uint v = randomness;
            
            /**
             *   This code attempts to force enough chnge in the passed random value
             *   so that can look like it generates multiple random numbers.
            */
            if (counter % 2 == 0) {
                if (counter > 0){
                    v = randomness / (100*counter);
                }
                /// Add 1 to prevent returning 0
                curValue = addmod(v, someValue1, rollee.sizeOfDie) + 1;
            } else {
                if (counter > 0) {
                    v = randomness / (99*counter);
                }
                /// Add 1 to prevent returning 0
                curValue = mulmod(v, someValue2, rollee.sizeOfDie) + 1;
            }

            calculatedValue += int(curValue);
            rollee.rolledValues.push(curValue);
            ++counter;
        }
        calculatedValue += rollee.adjustment;
        rollee.result = calculatedValue;
        _results[_rollers[requestId]] = rollee;

        emit DiceLanded(requestId, rollee.rollee, rollee.rolledValues, rollee.adjustment, calculatedValue);
    }


    function isOwner() internal view virtual returns (bool) {
        return msg.sender == owner();
    }
}

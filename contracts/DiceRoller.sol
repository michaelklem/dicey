// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// https://docs.chain.link/docs/vrf-contracts/
// Testnet LINK are available from https://faucets.chain.link/kovan
// Testnet ETH are available from https://faucets.chain.link/kovan

//   const contract = await contractFactory.deploy(
//     "0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9", 
//     "0xa36085F69e2889c224210F603D836748e7dC0088", 
//     "0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4", 
//     hre.ethers.utils.parseEther('0.1') // 100000000000000000
//   ); 
// 
// https://docs.chain.link/docs/vrf-contracts/

contract DiceRoller is VRFConsumerBase, Ownable {

    bytes32 private s_keyHash;
    uint256 private s_fee;
    int private constant ROLL_IN_PROGRESS = 42;
    int finalValue;
    int callbackCalled;

    struct DiceRollee {
        address rollee;
        uint256 randomness;
        uint256 d20Value;
        uint numberOfDice; // 1 = roll once, 4 = roll for die
        uint sizeOfDie; // 6 = 6 sided die, 20 = 20 sided die
        int adjustment; //+/- 4
        int result;
        uint[] rolledValues;
    }
    uint[] grolledValues;
    // s_rollers stores a mapping between the requestID (returned when a request is made), and the address of the roller. This is so the contract can keep track of who to assign the result to when it comes back.
    mapping(bytes32 => address) private s_rollers;
    // mapping(bytes32 => DiceRollee) private s_rollers;

    // s_results stores the roller and the result of the dice roll.
    // mapping(address => uint256) private s_results;
    mapping(address => DiceRollee) private s_results;
    uint256 xrandomness;
    uint256 xd100Value;
    uint256 xd20Value;
    uint256 xd8Value;
    uint256 xd6Value;
    uint256 xd4Value;
    uint32 x32Randomness;

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
    // event DiceWasRolled(address roller, uint result);
    // DiceRolled event
    event DiceRolled(bytes32 indexed requestId, address indexed roller);
    event DiceLanded(bytes32 indexed requestId, uint256 indexed result);

   // kovan
    // vrf coordinator = 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
    // link = 0xa36085F69e2889c224210F603D836748e7dC0088
    // keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
    // fee = 100000000000000000
    constructor(address vrfCoordinator, address link, bytes32 keyHash, uint256 fee)
        VRFConsumerBase(vrfCoordinator, link)
    {
        s_keyHash = keyHash;
        s_fee = fee;
    }

    // Any Eth and LINK token will get sent back to me before the contract is killed.
    function kill() external onlyOwner {
        LINK.transfer(owner(), getLINKBalance());
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
    

    /**
     * @notice Requests randomness
     * @dev Warning: if the VRF response is delayed, avoid calling requestRandomness repeatedly
     * as that would give miners/VRF operators latitude about which VRF response arrives first.
     * @dev You must review your implementation details with extreme care.
     *
     * @param roller address of the roller
     */
    function rollDice(address roller, uint _numberOfDice, uint _dieSize, int _adjustment) public onlyOwner returns (bytes32 requestId) {
        // checking LINK balance
        require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK to pay fee");


        // checking if roller has already rolled die
        // require(s_results[roller] == 0, "Already rolled");

        // requesting randomness
        requestId = requestRandomness(s_keyHash, s_fee);
        s_rollers[requestId] = roller;

        // emitting event to signal rolling of die
        // struct DiceRollee {
        //     address _rollee;
        //     uint256 randomness;
        //     uint256 d20Value;
        //     uint numberOfDice; // 1 = roll once, 4 = roll for die
        //     uint sizeOfDie; // 6 = 6 sided die, 20 = 20 sided die
        //     int adjustment; //+/- 4
        //     int result;
        // }

        // int[] memory tempX = new int[](_numberOfDice);
        DiceRollee memory diceRollee2 = DiceRollee(roller,0, 0, _numberOfDice, _dieSize, _adjustment, ROLL_IN_PROGRESS, new uint[](_numberOfDice));
        // s_results[roller] = ROLL_IN_PROGRESS;
        s_results[roller] = diceRollee2;
        emit DiceRolled(requestId, roller);
    }

    /**
     * @notice Callback function used by VRF Coordinator to return the random number
     * to this contract.
     * @dev Some action on the contract state should be taken here, like storing the result.
     * @dev WARNING: take care to avoid having multiple VRF requests in flight if their order of arrival would result
     * in contract states with different outcomes. Otherwise miners or the VRF operator would could take advantage
     * by controlling the order.
     * @dev The VRF Coordinator will only send this function verified responses, and the parent VRFConsumerBase
     * contract ensures that this method only receives randomness from the designated VRFCoordinator.
     *
     * @param requestId bytes32
     * @param randomness The random result returned by the oracle
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 d20Value = (randomness % 20) + 1;
        // int256 d20Value = int((randomness % 20) + 1);


        
        xd100Value = (randomness % 100) + 1;
        xd8Value = (randomness % 8) + 1;
        xd6Value = (randomness % 6) + 1;
        xd4Value = (randomness % 4) + 1;
        // s_results[s_rollers[requestId]] = d20Value;
        DiceRollee storage rollee = s_results[s_rollers[requestId]];
        delete rollee.rolledValues;
        rollee.d20Value = d20Value;
        rollee.result = 123;
        rollee.randomness = randomness;

        //666
    //  struct DiceRollee {
    //     address rollee;
    //     uint256 randomness;
    //     uint256 d20Value;
    //     uint numberOfDice; // 1 = roll once, 4 = roll for die
    //     uint sizeOfDie; // 6 = 6 sided die, 20 = 20 sided die
    //     int adjustment; //+/- 4
    //     int result;
    //     int[] rolledValues;
    // }       
        uint counter;
        uint256 tempRandomness = randomness;
        int tempValue;
        callbackCalled = 999;
        // int[] memory rolledValues;
        delete grolledValues; // 
        while (counter < rollee.numberOfDice) {
            // Need to add one otherwise the value can be 0.
            uint curValue = uint(tempRandomness % rollee.sizeOfDie) + 1;
            tempValue += int(curValue);
            rollee.rolledValues.push(curValue);
            grolledValues.push(curValue);
            ++counter;
            tempRandomness = tempRandomness << 2;
        }
        tempValue += rollee.adjustment;
        rollee.result = tempValue;
        // rollee.rolledValues = grolledValues;
        finalValue = tempValue;

        s_results[s_rollers[requestId]] = rollee;

        xrandomness = randomness;
        x32Randomness = uint32(xrandomness);
        xd20Value = d20Value;
        emit DiceLanded(requestId, d20Value);
    }

    /**
     * @notice Get the house assigned to the player once the address has rolled
     * @param player address
     * @return house as a string
     */
    function house(address player) public view returns (string memory) {
        // require(s_results[player] != 0, "Dice not rolled");
        require(s_results[player].result != 0, "Dice not rolled");
        // require(s_results[player] != ROLL_IN_PROGRESS, "Roll in progress");
        require(s_results[player].result != ROLL_IN_PROGRESS, "Roll in progress");
        return getHouseName(s_results[player].d20Value);
    }

    function getHouseName(uint256 id) private pure returns (string memory) {
    string[20] memory houseNames = [
        "Targaryen",
        "Lannister",
        "Stark",
        "Tyrell",
        "Baratheon",
        "Martell",
        "Tully",
        "Bolton",
        "Greyjoy",
        "Arryn",
        "Frey",
        "Mormont",
        "Tarley",
        "Dayne",
        "Umber",
        "Valeryon",
        "Manderly",
        "Clegane",
        "Glover",
        "Karstark"
        ];
        return houseNames[id - 1];
    }
    
    // returns historic data for specific address/user
    function getUserRolls(address _address) public view returns (DiceRoll[] memory) {
        return userRollHistory[_address];
    }

    // only allow the contract owner (me) to access this.
    function getAllUsers() public view returns (address[] memory) {
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

    function getRoller(address _roller) view public returns (DiceRollee memory) {
        return s_results[_roller];
    }

    function getxrandomness() view public returns (uint256) {
        return xrandomness;
    }

    function getxd20Value() view public returns (uint256) {
        return xd20Value;
    }

    function getxd100Value() view public returns (uint256) {
        return xd100Value;
    }

    function getxd8Value() view public returns (uint256) {
        return xd8Value;
    }

    function getxd6Value() view public returns (uint256) {
        return xd6Value;
    }

    function getxd4Value() view public returns (uint256) {
        return xd4Value;
    }

    function getx32Randomness() view public returns (uint256) {
        return x32Randomness;
    }

    function getBalance() view public returns (uint256) {
        return address(this).balance;
    }
    function getfinalValue() view public returns (int) {
        return finalValue;
    }
    function getcallbackCalled() view public returns (int) {
        return callbackCalled;
    }

    function getrolledValues() view public returns (uint[] memory) {
        return grolledValues;
    }

    // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
    // https://medium.com/coinmonks/get-token-balance-for-any-eth-address-by-using-smart-contracts-in-js-b603fef2061c
    // returns the amount of LINK tokens this contract has.
    function getLINKBalance() view public onlyOwner returns (uint256) {
       return LINK.balanceOf(address(this));
    }
}

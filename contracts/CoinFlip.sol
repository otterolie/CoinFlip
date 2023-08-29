// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import Chainlink VRFV2WrapperConsumerBase contract
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

// Define the CoinFlip contract, inheriting from VRFV2WrapperConsumerBase
contract CoinFlip is VRFV2WrapperConsumerBase {
    // Declare events for logging coin flip requests and results
    event CoinFlipRequest(uint256 requestId);
    event CoinFlipResult(uint256 requestId, bool didWin);

    // Define a struct to hold the status of each coin flip
    struct CoinFlipStatus {
        uint256 fees; // Fees paid for the request
        uint256 randomWord; // Random number generated
        address player; // Address of the player
        bool didWin; // Whether the player won or not
        bool fulfilled; // Whether the request has been fulfilled
        CoinFlipSelection choice; // Player's choice (HEADS or TAILS)
    }

    // Define an enum for coin flip selections (HEADS or TAILS)
    enum CoinFlipSelection {
        HEADS,
        TAILS
    }

    // Declare a mapping to store the status of each coin flip request
    mapping(uint256 => CoinFlipStatus) public statuses;

    // Declare constants for LINK token and VRF wrapper addresses
    address constant linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address constant vrfWrapperAddress =
        0x708701a1DfF4f478de54383E49a627eD4852C816;

    // Declare constants for entry fees, gas limit, etc.
    uint128 constant minimumEntryFees = 0.001 ether;
    uint32 constant callbackGasLimit = 1_000_000;
    uint32 constant numWords = 1;
    uint16 constant requestConfirmations = 3;

    // Constructor to initialize the contract
    constructor()
        payable
        VRFV2WrapperConsumerBase(linkAddress, vrfWrapperAddress)
    {}

    // Function to initiate a coin flip
    function flip(CoinFlipSelection choice) external payable returns (uint256) {
        // Ensure the minimum entry fee is sent
        require(msg.value >= minimumEntryFees, "Minimum entry fees not met");

        // Request randomness from Chainlink VRF
        uint256 requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );

        // Store the coin flip status
        statuses[requestId] = CoinFlipStatus({
            fees: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWord: 0,
            player: msg.sender,
            didWin: false,
            fulfilled: false,
            choice: choice
        });

        // Emit an event to log the coin flip request
        emit CoinFlipRequest(requestId);
        return requestId;
    }

    // Function to fulfill the random number request
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        // Ensure the request exists
        require(statuses[requestId].fees > 0, "Request is not found");

        // Update the coin flip status
        statuses[requestId].fulfilled = true;
        statuses[requestId].randomWord = randomWords[0];

        // Determine the coin flip result
        CoinFlipSelection result = CoinFlipSelection.HEADS;
        if (randomWords[0] % 2 == 0) {
            result = CoinFlipSelection.TAILS;
        }

        // Check if the player won and transfer funds if so
        if (statuses[requestId].choice == result) {
            statuses[requestId].didWin = true;

            uint256 originalWinnings = statuses[requestId].fees * 2; // Original winnings, double the bet
            uint256 taxAmount = (originalWinnings * 5) / 100; // Calculate 5% tax
            uint256 winningsAfterTax = originalWinnings - taxAmount; // Subtract the tax to get the final winnings

            payable(statuses[requestId].player).transfer(winningsAfterTax); // Transfer winnings after tax
        }

        // Emit an event to log the coin flip result
        emit CoinFlipResult(requestId, statuses[requestId].didWin);
    }

    // Function to get the status of a coin flip request
    function getStatus(
        uint256 requestId
    ) public view returns (CoinFlipStatus memory) {
        return statuses[requestId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
//  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

// After some `deadline` allow anyone to call an `execute()` function
//  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

// if the `threshold` was not met, allow everyone to call a `withdraw()` function

// Add a `withdraw()` function to let users withdraw their balance

// Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

// Add the `receive()` special function that receives eth and calls stake()

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    //events
    event Stake(address indexed from, uint256 indexed amount);

    //mapping
    mapping(address => uint256) public balances;

    //state variables
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool public hasBeenCompleted = false;

    //constructor
    //change from original: removed public declaration from constructor
    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    //modifier
    modifier notCompleted() {
        require(!hasBeenCompleted);
        _;
    }
    modifier deadlinePassed() {
        require(block.timestamp >= deadline);
        _;
    }
    modifier deadlineNotPassed() {
        require(!(block.timestamp >= deadline));
        _;
    }

    //functions

    function stake() public payable notCompleted deadlineNotPassed {
        uint256 senderBalance = balances[msg.sender];
        balances[msg.sender] = senderBalance + msg.value;

        //emit to frontend somehow
        emit Stake(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function execute() public deadlinePassed {
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            withdraw();
        }
        hasBeenCompleted = true;
    }

    function withdraw() public {
        require(
            (block.timestamp >= deadline),
            "Cannot withdraw before deadline"
        );
        address payable withdrawer = payable(msg.sender);
        uint256 amount = balances[withdrawer];
        balances[withdrawer] = 0;

        (bool success, ) = withdrawer.call{value: amount}(""); //maybe change this line so it transfers directly

        require(success, "Transfer failed / No funds to withdraw");
    }

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return (deadline - block.timestamp);
        }
    }

    //receive
    receive() external payable {
        stake();
    }
}

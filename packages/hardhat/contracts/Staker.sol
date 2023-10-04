// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
	ExampleExternalContract public exampleExternalContract;
	mapping(address => uint256) public balances;
	//mapping(address => uint256) public deadlines;
	uint256 public totalBalance;
	uint256 public constant threshold = 1 ether;
	uint256 public deadline = block.timestamp + 60 seconds;
	bool public openForWithdraw = false;
	bool public alreadyExecuted = false;

	constructor(address exampleExternalContractAddress) {
		exampleExternalContract = ExampleExternalContract(
			exampleExternalContractAddress
		);
	}

	// Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
	// (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
	event Stake(address _stakerAddress, uint256 _stakerAmount);

	function stake() public payable {
		balances[msg.sender] += msg.value;
		totalBalance += msg.value;
		emit Stake(msg.sender, msg.value);
	}

	modifier deadlinePassed() {
		require(block.timestamp >= deadline, "Not deadline yet!");
		_;
	}
	modifier notCompleted() {
		require(!exampleExternalContract.completed(), "The balance was staked!");
		_;
	}
	modifier notExecuted() {
		require(!alreadyExecuted, "It was executed already!");
		_;
	}

	// After some `deadline` allow anyone to call an `execute()` function
	// If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
	function execute() public deadlinePassed notExecuted notCompleted {
		require(
			address(this).balance >= threshold,
			"The threshold was not met, and the balance wasn't staked!"
		);
		exampleExternalContract.complete{ value: address(this).balance }();
		//openForWithdraw = true;
		alreadyExecuted = true;
		totalBalance = 0;
	}

	// If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
	function withdraw() public payable deadlinePassed notCompleted {
		require(
			address(this).balance < threshold,
			"The threshold was met, no withdrawn allowed!"
		);
		uint256 _stakerBalance = balances[msg.sender];
		require(_stakerBalance > 0, "You don't have balance!");
		(bool success, ) = msg.sender.call{ value: _stakerBalance }("");
		require(success, "Unable to withdraw");
		balances[msg.sender] = 0;
		totalBalance -= _stakerBalance;
	}

	// Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
	function timeLeft() external view returns (uint256) {
		if (block.timestamp >= deadline) {
			return 0;
		}
		return deadline - block.timestamp;
	}

	// Add the `receive()` special function that receives eth and calls stake()
	receive() external payable {
		stake();
	}
}

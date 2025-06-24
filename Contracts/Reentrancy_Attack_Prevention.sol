// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Reentrancy Attack Prevention
 * @dev Demonstrates secure patterns to prevent reentrancy attacks
 * @author Smart Contract Security Team
 */

contract Project {
    // State variables
    mapping(address => uint256) private balances;
    uint256 private totalDeposits;
    bool private locked;
    
    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event EmergencyWithdrawal(address indexed user, uint256 amount);
    
    // Modifiers
    modifier nonReentrant() {
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }
    
    modifier validAmount(uint256 amount) {
        require(amount > 0, "Amount must be greater than 0");
        _;
    }
    
    modifier hasSufficientBalance(uint256 amount) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        _;
    }
    
    /**
     * @dev Allows users to deposit Ether into the contract
     * @notice This function is secure against reentrancy attacks
     */
    function secureDeposit() external payable validAmount(msg.value) nonReentrant {
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @dev Allows users to withdraw their deposited Ether securely
     * @param amount The amount to withdraw in wei
     * @notice Uses checks-effects-interactions pattern to prevent reentrancy
     */
    function secureWithdraw(uint256 amount) 
        external 
        validAmount(amount)
        hasSufficientBalance(amount)
        nonReentrant 
    {
        // Checks (already done in modifiers)
        
        // Effects - Update state before external calls
        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        
        // Interactions - External calls last
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }
    
    /**
     * @dev Emergency withdrawal function with additional security measures
     * @notice Withdraws entire balance of the caller
     */
    function emergencyWithdraw() external nonReentrant {
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "No balance to withdraw");
        
        // Effects first
        balances[msg.sender] = 0;
        totalDeposits -= userBalance;
        
        // Interactions last
        (bool success, ) = payable(msg.sender).call{value: userBalance}("");
        require(success, "Emergency withdrawal failed");
        
        emit EmergencyWithdrawal(msg.sender, userBalance);
    }
    
    // View functions
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
    
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }
    
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    // Contract balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

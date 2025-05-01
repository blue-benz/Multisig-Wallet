// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    address[] public owners;
    uint256 public required;
    
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }
    
    mapping(uint256 => mapping(address => bool)) public confirmations;
    Transaction[] public transactions;
    
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    
    modifier onlyWallet() {
        require(msg.sender == address(this), "Only wallet");
        _;
    }
    
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid required");
        owners = _owners;
        required = _required;
    }
    
    function submitTransaction(address to, uint256 value, bytes memory data) public returns (uint256) {
        uint256 transactionId = transactions.length;
        transactions.push(Transaction({
            to: to,
            value: value,
            data: data,
            executed: false
        }));
        emit Submission(transactionId);
        confirmTransaction(transactionId);
        return transactionId;
    }
    
    function confirmTransaction(uint256 transactionId) public {
        require(transactions[transactionId].to != address(0), "Transaction does not exist");
        require(!confirmations[transactionId][msg.sender], "Already confirmed");
        
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        
        executeTransaction(transactionId);
    }
    
    function executeTransaction(uint256 transactionId) public {
        require(!transactions[transactionId].executed, "Already executed");
        
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count++;
            }
        }
        
        require(count >= required, "Not enough confirmations");
        
        transactions[transactionId].executed = true;
        (bool success, ) = transactions[transactionId].to.call{value: transactions[transactionId].value}(transactions[transactionId].data);
        require(success, "Transaction failed");
        emit Execution(transactionId);
    }
}

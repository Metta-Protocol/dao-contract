// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MettaDAO is ERC20, Ownable {
    mapping(address => bool) public whitelisted;
    ERC20 public mettaToken;
    ERC20 public buyToken;

    struct DaoTokenOrder {
        uint id;
        address sender;
        uint orderAmount;
        bool isApproved;
    }

    uint daoTokenOrderCount;

    mapping(uint => DaoTokenOrder) public daoTokenOrders;
    
    event DaoTokenOrderCreated(uint indexed id, address indexed sender, uint orderAmount);
    event OrderCancelled(uint indexed id);
    event OrderApproved(uint indexed id);

    constructor(address _mettaTokenAddress, address _buyTokenAddress, address initialOwner) ERC20("MettaDAO", "MTD") Ownable(initialOwner) {
        mettaToken = ERC20(_mettaTokenAddress);
        buyToken = ERC20(_buyTokenAddress);
    }

    function whitelistAddress(address _address) public onlyOwner {
        whitelisted[_address] = true;
    }

    function removeWhitelistAddress(address _address) public onlyOwner {
        whitelisted[_address] = false;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(whitelisted[msg.sender], "Sender is not whitelisted");
        require(whitelisted[recipient], "Recipient is not whitelisted");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(whitelisted[sender], "Sender is not whitelisted");
        require(whitelisted[recipient], "Recipient is not whitelisted");
        return super.transferFrom(sender, recipient, amount);
    }

    function exchangeMettaForMettaDAO(uint256 mettaAmount) public {
        require(mettaToken.transferFrom(msg.sender, address(this), mettaAmount), "Failed to transfer Metta tokens");
        _mint(msg.sender, mettaAmount); // Assuming 1:1 ratio for simplicity
    }

    function setMettaTokenAddress(address _mettaTokenAddress) public onlyOwner {
        mettaToken = ERC20(_mettaTokenAddress);
    }

 
    function createDaoTokenOrder(uint256 mettaAmount) external {
        require(whitelisted[msg.sender], "Sender is not whitelisted");
        //require(mettaToken.transferFrom(msg.sender, address(this), mettaAmount), "Failed to transfer Metta tokens");
        uint orderId = daoTokenOrderCount++;
        daoTokenOrders[orderId] = DaoTokenOrder({
            id: orderId,
            sender: msg.sender,
            orderAmount: mettaAmount,
            isApproved: false 
        });
        
        emit DaoTokenOrderCreated(orderId, msg.sender, mettaAmount);

    }
    

    function cancelDaoTokenOrder(uint id) external {
        
        require(daoTokenOrders[id].sender == msg.sender, "Only the sender can cancel the order");

        require(!daoTokenOrders[id].isApproved, "Order already processed");

        delete daoTokenOrders[id];

        emit OrderCancelled(id);
    }
    
    function emergencyWithdraw(address tokenAddress) public onlyOwner {
        uint256 amount = ERC20(tokenAddress).balanceOf(address(this)); 

         ERC20(tokenAddress).transfer(owner(), amount);
    }

    function approveOrder(uint id) public onlyOwner {
        require(daoTokenOrders[id].id != 0, "Order does not exist");

        require(!daoTokenOrders[id].isApproved, "Order already approved");

        daoTokenOrders[id].isApproved = true;

        emit OrderApproved(id);
    }
    


}

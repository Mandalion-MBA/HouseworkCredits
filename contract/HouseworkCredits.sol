// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract HouseworkCredits {
    address[3] public accounts;
    mapping(address => uint256) public balanceOf;
    mapping(address => string) public nameOf;

    event CreditsSent(address indexed from, address indexed to, uint256 amount, string reason);

    constructor(address[3] memory _accounts, string[3] memory _names) {
        for (uint256 i = 0; i < 3; i++) {
            accounts[i] = _accounts[i];
            nameOf[_accounts[i]] = _names[i];
            balanceOf[_accounts[i]] = 3;
        }
    }

    function sendCredits(address to, uint256 amount, string calldata reason) external {
        require(isKnownAccount(msg.sender), "Sender is not a known account");
        require(isKnownAccount(to), "Recipient is not a known account");
        require(balanceOf[msg.sender] >= amount, "Not enough credits");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit CreditsSent(msg.sender, to, amount, reason);
    }

    function isKnownAccount(address a) public view returns (bool) {
        return a == accounts[0] || a == accounts[1] || a == accounts[2];
    }

    function getAllAccounts() external view returns (address[3] memory) {
        return accounts;
    }

    function getAllBalances() external view returns (uint256[3] memory balances) {
        for (uint256 i = 0; i < 3; i++) {
            balances[i] = balanceOf[accounts[i]];
        }
    }
}

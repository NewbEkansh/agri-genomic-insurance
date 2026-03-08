// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FarmInsurance {
    address public owner;
    address public oracle;

    struct Farmer {
        address wallet;
        uint256 insuredAmountWei;
        bool active;
        uint256 registeredAt;
    }

    mapping(string => Farmer) public farmers;
    mapping(address => bool) public payoutGuard;
    uint256 public poolBalance;

    event FarmerRegistered(string farmId, address wallet, uint256 amount);
    event PayoutTriggered(string farmId, address wallet, uint256 amount, uint8 pct);
    event PoolFunded(address funder, uint256 amount);

    modifier onlyOwner() { require(msg.sender == owner, 'Not owner'); _; }
    modifier onlyOracle() { require(msg.sender == oracle, 'Not oracle'); _; }
    modifier noReentrant(address w) {
        require(!payoutGuard[w], 'Reentrant call');
        payoutGuard[w] = true; _; payoutGuard[w] = false;
    }

    constructor(address _oracle) {
        owner = msg.sender;
        oracle = _oracle;
    }

    function fundPool() external payable {
        require(msg.value > 0, 'Must send ETH');
        poolBalance += msg.value;
        emit PoolFunded(msg.sender, msg.value);
    }

    function registerFarmer(string calldata farmId, address wallet, uint256 insuredWei)
        external onlyOracle {
        require(wallet != address(0), 'Invalid wallet');
        require(insuredWei > 0, 'Amount must be > 0');
        require(!farmers[farmId].active, 'Already registered');
        farmers[farmId] = Farmer(wallet, insuredWei, true, block.timestamp);
        emit FarmerRegistered(farmId, wallet, insuredWei);
    }

    function triggerPayout(string calldata farmId, uint8 payoutPercent, string calldata txNote)
        external onlyOracle noReentrant(farmers[farmId].wallet) {
        Farmer storage f = farmers[farmId];
        require(f.active, 'Farmer not active');
        require(payoutPercent > 0 && payoutPercent <= 100, 'Invalid percent');
        uint256 amount = (f.insuredAmountWei * payoutPercent) / 100;
        require(poolBalance >= amount, 'Insufficient pool');
        poolBalance -= amount;
        (bool ok,) = f.wallet.call{value: amount}('');
        require(ok, 'Transfer failed');
        emit PayoutTriggered(farmId, f.wallet, amount, payoutPercent);
    }

    function getPoolBalance() external view returns (uint256) { return poolBalance; }
    function getFarmer(string calldata farmId) external view returns (Farmer memory) { return farmers[farmId]; }
    function updateOracle(address _new) external onlyOwner { oracle = _new; }
    function withdrawResidual() external onlyOwner {
        uint256 amt = poolBalance; poolBalance = 0;
        (bool ok,) = owner.call{value: amt}(''); require(ok);
    }

    receive() external payable { poolBalance += msg.value; }
}
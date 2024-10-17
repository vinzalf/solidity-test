// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LendingPoolMock {
    event FlashLoanCalled(address asset, uint256 amount, address initiator);

    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external {
        emit FlashLoanCalled(asset, amount, receiverAddress);
    }
}
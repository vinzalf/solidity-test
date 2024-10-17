// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AddressesProviderMock {
    address public pool;

    constructor(address _pool) {
        pool = _pool;
    }

    function getPool() external view returns (address) {
        return pool;
    }
}
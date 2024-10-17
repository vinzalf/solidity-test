// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UniswapRouterMock {
    event SwapExactTokensForTokensCalled(uint amountIn, uint amountOutMin, address[] path, address to);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        emit SwapExactTokensForTokensCalled(amountIn, amountOutMin, path, to);

        // Mock token output amounts
        amounts = new uint[](path.length);
        for (uint i = 0; i < path.length; i++) {
            amounts[i] = amountIn - (i * 100);  // Mock some decreasing token amounts
        }
        return amounts;
    }

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts) {
        // Mock the output based on amountIn
        amounts = new uint[](path.length);
        for (uint i = 0; i < path.length; i++) {
            amounts[i] = amountIn - (i * 100);  // Mock decreasing amounts
        }
    }
}
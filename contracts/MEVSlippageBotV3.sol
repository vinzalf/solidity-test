// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract MEVSlippageBotV3 is IFlashLoanSimpleReceiver {
    address public owner;
    IUniswapV2Router public uniswapRouter;
    IPool public lendingPool;
    IPoolAddressesProvider public addressesProvider;

    constructor(address _uniswapRouter, address _lendingPool, address _addressesProvider) {
        owner = msg.sender;
        uniswapRouter = IUniswapV2Router(_uniswapRouter);
        lendingPool = IPool(_lendingPool);
        addressesProvider = IPoolAddressesProvider(_addressesProvider);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // Unpack params
        (address[] memory path, uint256 minAmountOut) = abi.decode(params, (address[], uint256));

        // Perform the slippage check and arbitrage using the borrowed assets
        uint256 amountIn = amount;

        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(amountIn, path);
        uint256 amountOut = amountsOut[amountsOut.length - 1];

        // Check if amountOut meets slippage threshold
        require(amountOut >= minAmountOut, "Slippage condition not met");

        // Execute the swap
        uniswapRouter.swapExactTokensForTokens(
            amountIn, 
            minAmountOut, 
            path, 
            address(this), 
            block.timestamp + 300
        );

        // Pay back the loan and the premium (fees)
        uint256 totalDebt = amount + premium;
        IERC20(asset).approve(address(lendingPool), totalDebt);

        return true;
    }

    function startFlashLoan(
        address asset, 
        uint256 amount, 
        address[] memory path, 
        uint256 minAmountOut
    ) external onlyOwner {
        address receiverAddress = address(this);

        // Create data to pass to executeOperation
        bytes memory params = abi.encode(path, minAmountOut);

        // Borrow from Aave V3 pool
        lendingPool.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            0 // referral code, set to 0 for no referral
        );
    }

    // Aave V3 requires these functions for the FlashLoan receiver contract
    function ADDRESSES_PROVIDER() external view override returns (IPoolAddressesProvider) {
        return addressesProvider;
    }

    function POOL() external view override returns (IPool) {
        return lendingPool;
    }

    // Withdraw profits for the owner
    function withdraw(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(owner, IERC20(tokenAddress).balanceOf(address(this)));
    }

    // Remove the deprecated selfdestruct
    // Function to safely withdraw all Ether to the owner
    function withdrawEther() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MEVSlippageBotV3", function () {
  let owner, addr1;
  let MEVSlippageBotV3, mevBot;

  // Mock contracts
  let uniswapRouterMock, lendingPoolMock, addressesProviderMock;

  beforeEach(async function () {
    // Get signers
    [owner, addr1] = await ethers.getSigners();

    // Deploy Uniswap Router Mock
    const UniswapRouterMock = await ethers.getContractFactory("UniswapRouterMock");
    uniswapRouterMock = await UniswapRouterMock.deploy();
    await uniswapRouterMock.deployed();  // Ensure the contract is fully deployed

    // Deploy Lending Pool Mock
    const LendingPoolMock = await ethers.getContractFactory("LendingPoolMock");
    lendingPoolMock = await LendingPoolMock.deploy();
    await lendingPoolMock.deployed();  // Ensure the contract is fully deployed

    // Deploy Addresses Provider Mock
    const AddressesProviderMock = await ethers.getContractFactory("AddressesProviderMock");
    addressesProviderMock = await AddressesProviderMock.deploy(lendingPoolMock.address);
    await addressesProviderMock.deployed();  // Ensure the contract is fully deployed

    // Deploy the MEVSlippageBotV3 contract
    const MEVSlippageBotV3 = await ethers.getContractFactory("MEVSlippageBotV3");
    mevBot = await MEVSlippageBotV3.deploy(
      uniswapRouterMock.address,
      lendingPoolMock.address,
      addressesProviderMock.address
    );
    await mevBot.deployed();  // Ensure the contract is fully deployed
  });

  it("Should deploy and set the correct owner", async function () {
    expect(await mevBot.owner()).to.equal(owner.address);
  });

  it("Should be able to start a flash loan", async function () {
    const asset = ethers.constants.AddressZero;  // Mock token address
    const amount = ethers.utils.parseUnits("100", 18);  // 100 tokens
    const path = [ethers.constants.AddressZero, ethers.constants.AddressZero];  // Mock swap path
    const minAmountOut = ethers.utils.parseUnits("90", 18);  // Minimum output

    // Mock the flash loan initiation
    await expect(mevBot.startFlashLoan(asset, amount, path, minAmountOut))
      .to.emit(lendingPoolMock, "FlashLoanCalled")
      .withArgs(asset, amount, mevBot.address);
  });

  it("Should execute a token swap on Uniswap", async function () {
    const asset = ethers.constants.AddressZero;  // Mock token address
    const amount = ethers.utils.parseUnits("100", 18);  // 100 tokens
    const path = [ethers.constants.AddressZero, ethers.constants.AddressZero];  // Mock swap path
    const minAmountOut = ethers.utils.parseUnits("90", 18);  // Minimum output

    // Call the Uniswap mock to simulate swap
    const amounts = await uniswapRouterMock.getAmountsOut(amount, path);
    await expect(uniswapRouterMock.swapExactTokensForTokens(
      amount, 
      minAmountOut, 
      path, 
      mevBot.address, 
      Math.floor(Date.now() / 1000) + 300
    ))
    .to.emit(uniswapRouterMock, "SwapExactTokensForTokensCalled")
    .withArgs(amount, minAmountOut, path, mevBot.address);
    
    expect(amounts[amounts.length - 1]).to.be.gte(minAmountOut);
  });

  it("Should allow the owner to withdraw tokens", async function () {
    const tokenAddress = ethers.constants.AddressZero; // Mock token address

    // Call the withdraw function
    await expect(mevBot.withdraw(tokenAddress))
      .to.emit(mevBot, "Transfer")
      .withArgs(owner.address, 0);  // Mock transfer with no balance
  });
});
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {FlashMultihop, IUniswapV3Pool, ISwapRouter02, IERC20, IWETH9} from "../src/FlashMultihop.sol";
import {IQuoterV2} from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
address constant SWAP_ROUTER_02 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
address constant QUOTER2 = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
address constant DAI_WETH_POOL_3000 = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;
address constant DAI_WETH_POOL_500 = 0x60594a405d53811d3BC4766596EFD80fd545A270;
uint24 constant FEE_0 = 3000;
uint24 constant FEE_1 = 500;

contract UniswapV3FlashTest is Test {
    IERC20 private constant dai = IERC20(DAI);
    IWETH9 private constant weth = IWETH9(WETH);
    ISwapRouter02 private constant router = ISwapRouter02(SWAP_ROUTER_02);
    IQuoterV2 private constant quoter = IQuoterV2(QUOTER2);
    IUniswapV3Pool private constant pool0 = IUniswapV3Pool(DAI_WETH_POOL_3000);
    IUniswapV3Pool private constant pool1 = IUniswapV3Pool(DAI_WETH_POOL_500);
    UniswapV3FlashSwap private flashSwap;

    address account1 = address(1);

    uint256 private constant DAI_AMOUNT_IN = 10 * 1e18;

    function setUp() public {
        flashSwap = new UniswapV3FlashSwap();

        // Create an arbitrage opportunity - make WETH cheaper on pool0
        weth.deposit{value: 500 * 1e18}();
        weth.approve(address(router), 500 * 1e18);

        router.exactInputSingle(
            ISwapRouter02.ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: DAI,
                fee: FEE_0,
                recipient: address(0),
                amountIn: 500 * 1e18,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
        console.log("Dai balance:", dai.balanceOf(account1));
    }

    function test_flashSwap() public {
        uint256 bal0 = dai.balanceOf(address(this));
        flashSwap.flashSwap({
            pool0: address(pool0),
            fee1: FEE_1,
            tokenIn: DAI,
            tokenOut: WETH,
            amountIn: DAI_AMOUNT_IN
        });
        uint256 bal1 = dai.balanceOf(address(this));
        uint256 profit = bal1 - bal0;
        assertGt(profit, 0, "profit = 0");
        console.log("Profit %e", profit);
    }
}

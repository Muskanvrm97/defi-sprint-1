// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./MyToken.sol";

contract SimpleSwap {
    MyToken public tokenA;
    MyToken public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    string public name = "LP Token";
    string public symbol = "LP";
    uint256 public totalSupplyLP;
    mapping(address => uint256) public balanceOfLP;

    constructor(address _tokenA, address _tokenB) {
        tokenA = MyToken(_tokenA);
        tokenB = MyToken(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) public {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint256 lpTokens;

        if (totalSupplyLP == 0) {
            lpTokens = sqrt(amountA * amountB);
        } else {
            uint256 lpFromA = (amountA * totalSupplyLP) / reserveA;
            uint256 lpFromB = (amountB * totalSupplyLP) / reserveB;
            lpTokens = lpFromA < lpFromB ? lpFromA : lpFromB;
        }

        balanceOfLP[msg.sender] += lpTokens;
        totalSupplyLP += lpTokens;

        reserveA += amountA;
        reserveB += amountB;
    }

    function swap(address tokenIn, uint256 amountIn) public {
        require(
            tokenIn == address(tokenA) || tokenIn == address(tokenB),
            "Invalid Token"
        );

        bool isA = tokenIn == address(tokenA);

        MyToken inputToken = isA ? tokenA : tokenB;
        MyToken outputToken = isA ? tokenB : tokenA;

        uint256 inputReserve = isA ? reserveA : reserveB;
        uint256 outputReserve = isA ? reserveB : reserveA;

        inputToken.transferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut = (amountIn * outputReserve) /
            (inputReserve + amountIn);

        outputToken.transfer(msg.sender, amountOut);

        if (isA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }
    }

    function removeLiquidity(uint256 lpAmount) public {
        uint256 amountA = (lpAmount * reserveA) / totalSupplyLP;
        uint256 amountB = (lpAmount * reserveB) / totalSupplyLP;

        balanceOfLP[msg.sender] -= lpAmount;
        totalSupplyLP -= lpAmount;

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}

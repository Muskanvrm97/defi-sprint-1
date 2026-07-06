// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken token;
    address muskan = makeAddr("muskan");
    address prashant = makeAddr("prashant");
    address amm = makeAddr("amm");

    function setUp() public {
        vm.prank(muskan);
        token = new MyToken("Bonk", "BK", 1000);
    }

    function test_InitialBalance() public view {
        assertEq(token.balanceOf(muskan), 1000 * 10 ** 18);
        assertEq(token.balanceOf(prashant), 0);
    }

    function test_TransferWorks() public {
        vm.prank(muskan);
        token.transfer(prashant, 100 * 10 ** 18);

        assertEq(token.balanceOf(muskan), 900 * 10 ** 18);
        assertEq(token.balanceOf(prashant), 100 * 10 ** 18);
    }

    function test_TransferFailsIfInsufficientBal() public {
        vm.prank(prashant);
        vm.expectRevert("not enough tokens");
        token.transfer(muskan, 100 * 10 ** 18);
    }

    function test_ApproveAndTransferFrom() public {
        vm.prank(muskan);
        token.approve(amm, 300 * 10 ** 18);

        assertEq(token.allowance(muskan, amm), 300 * 10 ** 18);

        vm.prank(amm);
        token.transferFrom(muskan, amm, 200 * 10 ** 18);

        assertEq(token.balanceOf(muskan), 800 * 10 ** 18);
        assertEq(token.balanceOf(amm), 200 * 10 ** 18);
        assertEq(token.allowance(muskan, amm), 100 * 10 ** 18);
    }

    function test_TransferFromFailsWithoutApproval() public {
        vm.prank(amm);
        vm.expectRevert("Not approved");
        token.transferFrom(muskan, amm, 100 * 10 ** 18);
    }

    function test_TransferFromFailsIfExceedsAllowance() public {
        vm.prank(muskan);
        token.approve(amm, 100 * 10 ** 18);

        vm.prank(amm);
        vm.expectRevert("Not approved");
        token.transferFrom(muskan, amm, 200 * 10 ** 18);
    }

    // --- allowance race condition & atomic adjustment ---

    // Demonstrates the bug in approve(): a watching spender can drain the OLD
    // allowance, then also spend the NEW one, taking more than muskan intended.
    function test_ApproveRaceCondition_Exploit() public {
        // muskan approves 100
        vm.prank(muskan);
        token.approve(amm, 100 * 10 ** 18);

        // muskan changes his mind and broadcasts approve(50)... but the spender
        // front-runs it and drains the original 100 first.
        vm.prank(amm);
        token.transferFrom(muskan, amm, 100 * 10 ** 18);

        // now muskan's approve(50) lands, overwriting the (now 0) allowance to 50
        vm.prank(muskan);
        token.approve(amm, 50 * 10 ** 18);

        // spender pulls the new 50 too
        vm.prank(amm);
        token.transferFrom(muskan, amm, 50 * 10 ** 18);

        // muskan intended to allow 100 then 50, but lost 150
        assertEq(token.balanceOf(amm), 150 * 10 ** 18);
    }

    // decreaseAllowance closes the window: muskan reduces 100 -> 50 atomically.
    function test_DecreaseAllowance() public {
        vm.prank(muskan);
        token.approve(amm, 100 * 10 ** 18);

        vm.prank(muskan);
        token.decreaseAllowance(amm, 50 * 10 ** 18);

        assertEq(token.allowance(muskan, amm), 50 * 10 ** 18);
    }

    function test_IncreaseAllowance() public {
        vm.prank(muskan);
        token.approve(amm, 100 * 10 ** 18);

        vm.prank(muskan);
        token.increaseAllowance(amm, 25 * 10 ** 18);

        assertEq(token.allowance(muskan, amm), 125 * 10 ** 18);
    }

    function test_DecreaseAllowanceRevertsBelowZero() public {
        vm.prank(muskan);
        token.approve(amm, 40 * 10 ** 18);

        vm.prank(muskan);
        vm.expectRevert("decrease below zero");
        token.decreaseAllowance(amm, 50 * 10 ** 18);
    }
}

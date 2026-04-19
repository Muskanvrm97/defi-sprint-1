// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken token;
    address muskan = makeAddr("muskan");
    address prashant = makeAddr("prashant");
    address helen = makeAddr("helen");

    function setUp() public {
        vm.prank(muskan);
        token = new MyToken(1000);
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

        token.approve(prashant, 300 * 10 ** 18);

        assertEq(token.allowance(muskan, prashant), 300 * 10 ** 18);

        vm.prank(prashant);

        token.transferFrom(muskan, prashant, 200 * 10 ** 18);

        // Check balances
        assertEq(token.balanceOf(muskan), 800 * 10 ** 18);
        assertEq(token.balanceOf(prashant), 200 * 10 ** 18);

        // Check allowance decreased
        assertEq(token.allowance(muskan, prashant), 100 * 10 ** 18);
    }

    function test_TransferFromFailsWithoutApproval() public {
        vm.prank(prashant);
        vm.expectRevert("Not enough tokens");
        token.transferFrom(muskan, prashant, 200 * 10 ** 18);
    }

    function test_TransferFromFailsIfExceedsAllowance() public {
        // Muskan approves Prashant for 100 tokens
        vm.prank(muskan);
        token.approve(prashant, 100 * 10 ** 18);

        // Prashant tries to take 200 — more than approved
        vm.prank(prashant);
        vm.expectRevert("Not enough tokens");
        token.transferFrom(muskan, prashant, 200 * 10 ** 18);
    }
}

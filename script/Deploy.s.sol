// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/MyToken.sol";

contract DeployScript is Script {
    function run() public {
        vm.startBroadcast();
        new MyToken(1000);
        vm.stopBroadcast();
    }
}

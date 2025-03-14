// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MockResolver} from "src/1inch/MockResolver.sol";

contract DeployMockResolver is Script {
    MockResolver mockResolver;

    function run() external {
        vm.startBroadcast();
        mockResolver = new MockResolver();
        vm.stopBroadcast();
        console.log("MockResolver deployed at:", address(mockResolver));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {Payroll} from "src/Payroll.sol";

contract SetTokenPreferences is Script {
    address payroll;
    address constant LINK_ADDRESS = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    function setTokenPreferences(address mostRecentlyDeployment) public {
        address[] memory tokens = new address[](1);
        tokens[0] = LINK_ADDRESS;
        uint256[] memory percentages = new uint256[](1);
        percentages[0] = 50;

        vm.startBroadcast();
        Payroll(mostRecentlyDeployment).setPreferences(
            1,
            137, // set preferences for Polygon
            tokens,
            percentages
        );
        vm.stopBroadcast();
        console.log("Token preferences have been set");
    }

    function run() external {
        payroll = Vm(address(vm)).getDeployment(
            "Payroll",
            uint64(block.chainid)
        );

        setTokenPreferences(payroll);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {Payroll} from "src/Payroll.sol";

contract AddEmployee is Script {
    address payroll;
    address constant ANVIL_SECOND_ADDRESS =
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function addEmployee(address mostRecentlyDeployment) public {
        vm.startBroadcast();
        Payroll(mostRecentlyDeployment).addEmployee(
            1,
            ANVIL_SECOND_ADDRESS,
            1e10,
            block.timestamp,
            1 seconds
        );
        vm.stopBroadcast();
        console.log("We have the employee added");
    }

    function run() external {
        payroll = Vm(address(vm)).getDeployment(
            "Payroll",
            uint64(block.chainid)
        );

        addEmployee(payroll);
    }
}

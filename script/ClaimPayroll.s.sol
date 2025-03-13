// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {Payroll} from "src/Payroll.sol";

contract ClaimPayroll is Script {
    address payroll;

    function claimPayroll(address mostRecentlyDeployment) public {
        vm.startBroadcast();
        Payroll(mostRecentlyDeployment).claimPayroll(1);
        vm.stopBroadcast();
        console.log("Payroll has been claimed");
    }

    function run() external {
        payroll = Vm(address(vm)).getDeployment(
            "Payroll",
            uint64(block.chainid)
        );

        claimPayroll(payroll);
    }
}

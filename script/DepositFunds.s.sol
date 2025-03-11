// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {Payroll} from "src/Payroll.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DepositFunds is Script {
    address payroll;
    uint256 public constant DEPOSIT_AMOUNT = 1e10;
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    function depositFunds(address mostRecentlyDeployment) public {
        vm.startBroadcast();
        usdc.approve(mostRecentlyDeployment, DEPOSIT_AMOUNT);
        Payroll(mostRecentlyDeployment).depositFunds(DEPOSIT_AMOUNT);
        vm.stopBroadcast();
        console.log("The Payroll contract has been deposited with 1e10 USDC"); // 6 decimals => It's 1e10 / 1e6 = 1e4 USDC
    }

    function run() external {
        payroll = Vm(address(vm)).getDeployment(
            "Payroll",
            uint64(block.chainid)
        );

        depositFunds(payroll);
    }
}

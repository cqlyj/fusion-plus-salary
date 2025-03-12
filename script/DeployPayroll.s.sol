// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Payroll} from "src/Payroll.sol";

contract DeployPayroll is Script {
    address linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address[] allowedTokens = [linkAddress];
    uint256[] allowedChainIds = [137, 1];
    Payroll payroll;

    function run() external {
        // Deploy to the mainnet fork
        vm.startBroadcast();

        payroll = new Payroll(allowedTokens, allowedChainIds);

        vm.stopBroadcast();

        console.log(
            "The Payroll contract has been deployed at address: ",
            address(payroll)
        );
    }
}

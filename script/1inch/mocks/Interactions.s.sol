// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// send USDC to taker on Mainnet
contract MakerToTaker is Script {
    /// This is demo code, it just send USDC to taker on Mainnet and LINK to maker on Polygon
    address constant TAKER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 constant AMOUNT = 1e10;

    function run() external {
        vm.startBroadcast();
        IERC20(USDC).transfer(TAKER, AMOUNT);
        vm.stopBroadcast();
    }
}

// send LINK to maker on Polygon
contract TakerToMaker is Script {
    address constant TAKER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant MAKER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant LINK = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39; // Polygon LINK
    uint256 constant AMOUNT = 71072973539492589420;

    function run() external {
        vm.startBroadcast();
        IERC20(LINK).transfer(MAKER, AMOUNT);
        vm.stopBroadcast();

        console.log("Swap completed!");
    }
}

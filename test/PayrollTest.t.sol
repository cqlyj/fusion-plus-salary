// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Payroll} from "src/Payroll.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PayrollTest is Test {
    Payroll payroll;
    uint256 public fork;
    // Link token address on mainnet
    address constant LINK_ADDRESS = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    uint256 constant POLYGON_CHAIN_ID = 137;
    uint256 constant MAINNET_CHAIN_ID = 1;
    address constant DEFAULT_ANVIL_ADDRESS =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address EMPLOYEE_ADDRESS = makeAddr("employee");

    function setUp() external {
        string memory MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        fork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(fork);

        address[] memory allowedTokens = new address[](1);
        allowedTokens[0] = LINK_ADDRESS;
        uint256[] memory allowedChainIds = new uint256[](2);
        allowedChainIds[0] = POLYGON_CHAIN_ID;
        allowedChainIds[1] = MAINNET_CHAIN_ID;
        vm.prank(DEFAULT_ANVIL_ADDRESS);
        payroll = new Payroll(allowedTokens, allowedChainIds);

        deal(LINK_ADDRESS, DEFAULT_ANVIL_ADDRESS, 1e18);
        deal(payroll.getUsdcContract(), DEFAULT_ANVIL_ADDRESS, 1e18);
    }

    function testPayroll() external {
        vm.startPrank(DEFAULT_ANVIL_ADDRESS);
        IERC20(payroll.getUsdcContract()).approve(address(payroll), 1e18);
        payroll.depositFunds(1e18);
        vm.stopPrank();

        console.log("The Payroll contract has been deposited with 1e18 USDC");

        vm.startPrank(DEFAULT_ANVIL_ADDRESS);
        payroll.addEmployee(1, EMPLOYEE_ADDRESS, 1e16, block.timestamp, 1 days);
        vm.stopPrank();

        console.log("We have the employee added");

        vm.startPrank(EMPLOYEE_ADDRESS);
        address[] memory tokens = new address[](1);
        tokens[0] = LINK_ADDRESS;
        uint256[] memory percentages = new uint256[](1);
        percentages[0] = 50; // half usdc, half link
        payroll.setPreferences(1, POLYGON_CHAIN_ID, tokens, percentages);
        vm.stopPrank();
        console.log("The token preferences set");

        vm.warp(1 days + block.timestamp);
        console.log("Warping 1 day - pass the interval");

        vm.startPrank(EMPLOYEE_ADDRESS);
        payroll.claimPayroll(1);
        vm.stopPrank();
        console.log("The payroll has been claimed");
    }
}

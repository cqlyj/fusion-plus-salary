// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Payroll is Ownable {
    /*//////////////////////////////////////////////////////////////
                                 STRUCT
    //////////////////////////////////////////////////////////////*/

    struct Payment {
        uint256 employeeId;
        address connectedWallet;
        uint256 salaryAmount;
        uint256 lastPaymentDate;
        uint256 interval;
    }

    struct TokenPreference {
        address[] tokens;
        uint256[] percentages;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address[] private s_allowedTokens;
    IERC20 private immutable i_usdc =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // Mainnet USDC with 6 decimals
    mapping(uint256 employeeId => Payment) private s_idToPayment;
    mapping(uint256 employeeId => TokenPreference)
        private s_idToTokenPreference;
    uint256 private constant PERCENTAGE = 100;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event EmployeeAdded(
        uint256 indexed employeeId,
        address indexed connectedWallet,
        uint256 salaryAmount
    );

    event TokenPreferencesSet(
        uint256 indexed employeeId,
        address[] tokens,
        uint256[] percentages
    );

    event DepositFunds(uint256 amountOfUsdc);

    event PayrollClaimed(
        uint256 indexed employeeId,
        address indexed connectedWallet,
        uint256 amount
    );

    event Withdraw(uint256 amountOfUsdc);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Payroll__NotAuthorized();
    error Payroll__NotAllowedToken();
    error Payroll__InvalidSumOfPercentages();
    error Payroll__MismatchedLength();
    error Payroll__NotDueYet();
    error Payroll__InsufficientFunds();
    error Payroll__InvalidEmployeeId();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address[] memory allowedTokens) Ownable(msg.sender) {
        s_allowedTokens = allowedTokens;
    }

    /*//////////////////////////////////////////////////////////////
                            OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function depositFunds(uint256 amountOfUsdc) external payable onlyOwner {
        i_usdc.transferFrom(msg.sender, address(this), amountOfUsdc);

        emit DepositFunds(amountOfUsdc);
    }

    function addEmployee(
        uint256 employeeId,
        address connectedWallet,
        uint256 salaryAmount,
        uint256 lastPaymentDate,
        uint256 interval
    ) external onlyOwner {
        _validEmployeeId(employeeId);
        s_idToPayment[employeeId] = Payment(
            employeeId,
            connectedWallet,
            salaryAmount,
            lastPaymentDate,
            interval
        );

        emit EmployeeAdded(employeeId, connectedWallet, salaryAmount);
    }

    function withdrawFund(uint256 amountOfUsdc) external onlyOwner {
        i_usdc.transfer(msg.sender, amountOfUsdc);
        emit Withdraw(amountOfUsdc);
    }

    /*//////////////////////////////////////////////////////////////
                           EMPLOYEE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setTokenPreferences(
        uint256 employeeId,
        address[] calldata tokens,
        uint256[] calldata percentages
    ) external {
        if (s_idToPayment[employeeId].connectedWallet != msg.sender) {
            revert Payroll__NotAuthorized();
        }

        if (tokens.length != percentages.length) {
            revert Payroll__MismatchedLength();
        }

        // check the sum of percentages is less than 100
        // here the usdc is not included in the tokens array
        _checkTokens(tokens);
        _checkPercentage(percentages);

        s_idToTokenPreference[employeeId] = TokenPreference(
            tokens,
            percentages
        );

        emit TokenPreferencesSet(employeeId, tokens, percentages);
    }

    function claimPayroll(uint256 employeeId) external {
        Payment storage payment = s_idToPayment[employeeId];

        if (payment.connectedWallet != msg.sender) {
            revert Payroll__NotAuthorized();
        }

        if (block.timestamp < payment.lastPaymentDate + payment.interval) {
            revert Payroll__NotDueYet();
        }

        uint256 amount = payment.salaryAmount;
        if (i_usdc.balanceOf(address(this)) < amount) {
            revert Payroll__InsufficientFunds();
        }

        // here just add interval to the lastPaymentDate
        // since some employees might not claim their payroll for the last month
        // This way they can still claim their payroll for the last month
        payment.lastPaymentDate = payment.lastPaymentDate + payment.interval;

        // @update This will be updated to use the token preferences
        i_usdc.transfer(msg.sender, amount);

        emit PayrollClaimed(employeeId, msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _checkTokens(address[] calldata tokens) internal view {
        uint256 length = tokens.length;
        uint256 allowedTokenLength = s_allowedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            bool found = false;
            for (uint256 j = 0; j < allowedTokenLength; j++) {
                if (tokens[i] == s_allowedTokens[j]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                revert Payroll__NotAllowedToken();
            }
        }
    }

    function _checkPercentage(uint256[] calldata percentages) internal pure {
        uint256 length = percentages.length;
        uint256 sum = 0;
        for (uint256 i = 0; i < length; i++) {
            sum += percentages[i];
        }
        if (sum > PERCENTAGE) {
            revert Payroll__InvalidSumOfPercentages();
        }
    }

    function _validEmployeeId(uint256 employeeId) internal view {
        // This is to prevent overwriting an existing employee
        if (s_idToPayment[employeeId].employeeId != 0) {
            revert Payroll__InvalidEmployeeId();
        }
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getAllowTokens() external view returns (address[] memory) {
        return s_allowedTokens;
    }

    function getPayment(
        uint256 employeeId
    ) external view returns (Payment memory) {
        return s_idToPayment[employeeId];
    }

    function getTokenPreference(
        uint256 employeeId
    ) external view returns (TokenPreference memory) {
        return s_idToTokenPreference[employeeId];
    }

    function getUsdcBalance() external view returns (uint256) {
        return i_usdc.balanceOf(address(this));
    }

    function getUsdcContract() external view returns (address) {
        return address(i_usdc);
    }

    function getOwner() external view returns (address) {
        return owner();
    }
}

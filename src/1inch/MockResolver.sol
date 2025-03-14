// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IEscrowFactory} from "cross-chain-swap/contracts/interfaces/IEscrowFactory.sol";
import {IOrderMixin} from "limit-order-protocol/interfaces/IOrderMixin.sol";
import {IEscrow} from "cross-chain-swap/contracts/interfaces/IEscrow.sol";
import {IEscrowSrc} from "cross-chain-swap/contracts/interfaces/IEscrowSrc.sol";
import {IEscrowDst} from "cross-chain-swap/contracts/interfaces/IEscrowDst.sol";
import {IBaseEscrow} from "cross-chain-swap/contracts/interfaces/IBaseEscrow.sol";
import {TakerTraits} from "limit-order-protocol/libraries/TakerTraitsLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TimelocksLib} from "cross-chain-swap/contracts/libraries/TimelocksLib.sol";

contract MockResolver is Ownable {
    // https://portal.1inch.dev/documentation/apis/swap/fusion-plus/swagger/orders?method=get&path=%2Fv1.0%2Forder%2Fescrow
    IEscrowFactory immutable i_escrowFactory =
        IEscrowFactory(0xa7bCb4EAc8964306F9e3764f67Db6A7af6DdF99A);
    // https://github.com/1inch/limit-order-protocol/blob/master/README.md
    IOrderMixin immutable i_order =
        IOrderMixin(0x111111125421cA6dc452d289314280a0f8842A65);

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    /**
     * @notice Deploys a new escrow contract for maker on the source chain.
     * @param immutables The immutables of the escrow contract that are used in deployment.
     * @param order Order quote to fill.
     * @param r R component of signature.
     * @param vs VS component of signature.
     * @param amount Taker amount to fill
     * @param takerTraits Specifies threshold as maximum allowed takingAmount when takingAmount is zero, otherwise specifies
     * minimum allowed makingAmount. The 2nd (0 based index) highest bit specifies whether taker wants to skip maker's permit.
     * @param args Arguments that are used by the taker (target, extension, interaction, permit).
     */
    function deploySrc(
        IBaseEscrow.Immutables calldata immutables,
        IOrderMixin.Order calldata order,
        bytes32 r,
        bytes32 vs,
        uint256 amount,
        TakerTraits takerTraits,
        bytes calldata args
    ) external onlyOwner {
        IBaseEscrow.Immutables memory immutablesMem = immutables;
        immutablesMem.timelocks = TimelocksLib.setDeployedAt(
            immutables.timelocks,
            block.timestamp
        );
        address computed = i_escrowFactory.addressOfEscrowSrc(immutablesMem);
        (bool success, ) = address(computed).call{
            value: immutablesMem.safetyDeposit
        }("");
        if (!success) revert IBaseEscrow.NativeTokenSendingFailure();

        // _ARGS_HAS_TARGET = 1 << 251
        takerTraits = TakerTraits.wrap(
            TakerTraits.unwrap(takerTraits) | uint256(1 << 251)
        );
        bytes memory argsMem = abi.encodePacked(computed, args);
        i_order.fillOrderArgs(order, r, vs, amount, takerTraits, argsMem);
    }

    // /**
    //  * @notice Same as `fillOrder` but allows to specify arguments that are used by the taker.
    //  * @param order Order quote to fill
    //  * @param r R component of signature
    //  * @param vs VS component of signature
    //  * @param amount Taker amount to fill
    //  * @param takerTraits Specifies threshold as maximum allowed takingAmount when takingAmount is zero, otherwise specifies
    //  * minimum allowed makingAmount. The 2nd (0 based index) highest bit specifies whether taker wants to skip maker's permit.
    //  * @param args Arguments that are used by the taker (target, extension, interaction, permit)
    //  * @return makingAmount Actual amount transferred from maker to taker
    //  * @return takingAmount Actual amount transferred from taker to maker
    //  * @return orderHash Hash of the filled order
    //  */
    // function fillOrderArgs(
    //     IOrderMixin.Order calldata order,
    //     bytes32 r,
    //     bytes32 vs,
    //     uint256 amount,
    //     TakerTraits takerTraits,
    //     bytes calldata args
    // )
    //     external
    //     payable
    //     returns (uint256 makingAmount, uint256 takingAmount, bytes32 orderHash)
    // {
    //     return i_order.fillOrderArgs(order, r, vs, amount, takerTraits, args);
    // }

    function addressOfEscrowDst(
        IBaseEscrow.Immutables calldata immutables
    ) external view virtual returns (address) {
        return i_escrowFactory.addressOfEscrowDst(immutables);
    }

    function createDstEscrow(
        IBaseEscrow.Immutables calldata dstImmutables,
        uint256 srcCancellationTimestamp
    ) external payable {
        i_escrowFactory.createDstEscrow{value: msg.value}(
            dstImmutables,
            srcCancellationTimestamp
        );
    }

    /**
     * @notice Withdraws funds to a specified target.
     * @dev Withdrawal can only be made during the withdrawal period and with secret with hash matches the hashlock.
     * The safety deposit is sent to the caller.
     * @param secret The secret that unlocks the escrow.
     * @param target The address to withdraw the funds to.
     * @param immutables The immutables of the escrow contract.
     */
    function withdrawTo(
        address escrowSrc,
        bytes32 secret,
        address target,
        IEscrow.Immutables calldata immutables
    ) external {
        IEscrowSrc(escrowSrc).withdrawTo(secret, target, immutables);
    }

    /**
     * @notice Withdraws funds to a predetermined recipient.
     * @dev Withdrawal can only be made during the withdrawal period and with secret with hash matches the hashlock.
     * The safety deposit is sent to the caller.
     * @param secret The secret that unlocks the escrow.
     * @param immutables The immutables of the escrow contract.
     */
    function withdraw(
        address escrowDst,
        bytes32 secret,
        IBaseEscrow.Immutables calldata immutables
    ) external {
        IEscrowDst(escrowDst).withdraw(secret, immutables);
    }

    // TODO: Implement the rest of the functions
}

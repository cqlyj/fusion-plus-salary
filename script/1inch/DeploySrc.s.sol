// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MockResolver} from "src/1inch/MockResolver.sol";
import {Vm} from "forge-std/Vm.sol";
import {IBaseEscrow} from "cross-chain-swap/contracts/interfaces/IBaseEscrow.sol";
import {Address} from "cross-chain-swap/lib/solidity-utils/contracts/libraries/AddressLib.sol";
import {Timelocks} from "cross-chain-swap/contracts/libraries/TimelocksLib.sol";
import {IOrderMixin} from "limit-order-protocol/interfaces/IOrderMixin.sol";
import {MakerTraits} from "limit-order-protocol/libraries/MakerTraitsLib.sol";
import {TakerTraits} from "limit-order-protocol/libraries/TakerTraitsLib.sol";

contract DeploySrc is Script {
    // those values are retrieved from the fusion+ api
    bytes32 orderHash =
        0x4bfbdb2ed9f9c7e2d6f6d576c9447f2e299fddc26e14c431cbaf3e024421689c;
    bytes32 hashlock =
        0xdb0fd1131f1b9e113177c2ca77141042c5e0c1da655bb89acae9a78de0f952d1;
    Address maker =
        Address.wrap(uint160(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)); // for demo purpose we know the maker will be the second Anvil address
    Address taker =
        Address.wrap(uint160(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)); // for demo purpose we will set the employer as the taker. Yes, boss is also the swap taker!
    Address token =
        Address.wrap(uint160(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)); // USDC
    uint256 amount = 1000000000;
    uint256 safetyDeposit = 176909022990000;
    Timelocks timelocks;
    TakerTraits takerTraits;

    IBaseEscrow.Immutables immutables =
        IBaseEscrow.Immutables(
            orderHash, // Hash of the order.
            hashlock, // Hash of the secret.
            maker,
            taker,
            token,
            amount,
            safetyDeposit,
            timelocks
        );

    IOrderMixin.Order order =
        IOrderMixin.Order(
            9445680547397336521814649437822316726196018837947820098446270030205675929919, // salt
            maker,
            Address.wrap(uint160(0x0000000000000000000000000000000000000000)),
            token,
            Address.wrap(uint160(0xDA0000d4000015A526378bB6faFc650Cea5966F8)), // LINK on Polygon
            amount,
            71072973539492589420,
            MakerTraits.wrap(
                62419173104490761595518734106839027476313006583650176683635734654290568937472
            )
        );

    address mockResolver;
    uint256 makerPrivateKey =
        0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    function makeSignature() public view returns (bytes32, bytes32) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(makerPrivateKey, orderHash);
        bytes32 vs = bytes32((uint256(v - 27) << 255)) | s;

        return (r, vs);
    }

    function deploySrc(address payable mostRecentlyDeployment) public {
        (bytes32 r, bytes32 vs) = makeSignature();
        InteractionParams memory interaction = InteractionParams(
            bytes("0x"),
            bytes("0x"),
            bytes(
                "0xa7bcb4eac8964306f9e3764f67db6a7af6ddf99a000eed0000021d67d522b70000b400d34c00b2f20078000eed003c"
            ),
            bytes(
                "0xa7bcb4eac8964306f9e3764f67db6a7af6ddf99a000eed0000021d67d522b70000b400d34c00b2f20078000eed003c"
            ),
            bytes("0x"),
            bytes("0x"),
            bytes("0x"),
            bytes(
                "0xa7bcb4eac8964306f9e3764f67db6a7af6ddf99a67d5229f72f8a0c8c415454f629c000008db0fd1131f1b9e113177c2ca77141042c5e0c1da655bb89acae9a78de0f952d1000000000000000000000000000000000000000000000000000000000000008900000000000000000000000053e0bca35ec356bd5dddfebbd1fc0fd03fabad3900000000000000000000692cdb3ff7c000000000000000000087bc791374e0700000000000000240000001c8000000b40000030000000288000001ec00000024"
            )
        );

        bytes memory extension = buildExtension(interaction);

        bytes memory args = buildArgs(
            abi.encode(interaction),
            extension,
            0x70997970C51812dc3A010C7d01b50e0d17dc79C8
        );

        vm.startBroadcast();
        MockResolver(mostRecentlyDeployment).deploySrc(
            immutables,
            order,
            r,
            vs,
            amount,
            takerTraits,
            args // custom error 0xb2d25e49 => MissingOrderExtension
        );
        vm.stopBroadcast();

        console.log("Escrow deployed on source chain");
    }

    function run() external {
        mockResolver = Vm(address(vm)).getDeployment(
            "MockResolver",
            uint64(block.chainid)
        );

        // send some eth to the contract first
        vm.deal(address(mockResolver), 1e18);

        deploySrc(payable(mockResolver));
    }

    struct InteractionParams {
        bytes makerAssetSuffix;
        bytes takerAssetSuffix;
        bytes makingAmountData;
        bytes takingAmountData;
        bytes predicate;
        bytes permit;
        bytes preInteraction;
        bytes postInteraction;
    }

    function buildExtension(
        InteractionParams memory interactions
    ) public pure returns (bytes memory) {
        bytes[8] memory allInteractions = [
            interactions.makerAssetSuffix,
            interactions.takerAssetSuffix,
            interactions.makingAmountData,
            interactions.takingAmountData,
            interactions.predicate,
            interactions.permit,
            interactions.preInteraction,
            interactions.postInteraction
        ];
        bytes memory allInteractionsConcat = bytes.concat(
            interactions.makerAssetSuffix,
            interactions.takerAssetSuffix,
            interactions.makingAmountData,
            interactions.takingAmountData,
            interactions.predicate,
            interactions.permit,
            interactions.preInteraction,
            interactions.postInteraction,
            bytes("0x")
        );

        bytes32 offsets = 0;
        uint256 sum = 0;
        for (uint256 i = 0; i < allInteractions.length; i++) {
            if (allInteractions[i].length > 0) {
                sum += allInteractions[i].length;
            }
            offsets |= bytes32(sum << (i * 32));
        }

        bytes memory extension = "";
        if (allInteractionsConcat.length > 0) {
            extension = abi.encodePacked(offsets, allInteractionsConcat);
        }

        return extension;
    }

    function buildArgs(
        bytes memory interaction,
        bytes memory extension,
        address target
    ) public pure returns (bytes memory) {
        bytes memory targetBytes = target != address(0)
            ? abi.encodePacked(target)
            : abi.encodePacked("");
        bytes memory args = abi.encodePacked(
            targetBytes,
            extension,
            interaction
        );

        return args;
    }
}

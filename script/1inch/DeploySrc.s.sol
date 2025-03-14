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
        0x883ad3b7a6e9eef6e6ccbd63811f442d3b779c053d9f255ca9cc49fd87ff8c5d;
    bytes32 hashlock =
        0xef5c09a4f9dcde49e76b64009f2cfe02c308f0993f271332d1f9671d1c7af061;
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
            9445680536330710674639214029314565537344982747492504666726427626089400168223, // salt
            maker,
            Address.wrap(uint160(0x0000000000000000000000000000000000000000)),
            token,
            Address.wrap(uint160(0xDA0000d4000015A526378bB6faFc650Cea5966F8)), // LINK on Polygon
            amount,
            68950246988963384606,
            MakerTraits.wrap(
                62419173104490761595518734106935966576586521882755260756559723990326907502592
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

        vm.startBroadcast();
        MockResolver(mostRecentlyDeployment).deploySrc(
            immutables,
            order,
            r,
            vs,
            amount,
            takerTraits,
            bytes("") // custom error 0xb2d25e49 => MissingOrderExtension
            // TODO: fix this
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
}

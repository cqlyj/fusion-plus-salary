const {
  SDK,
  HashLock,
  PrivateKeyProviderConnector,
  NetworkEnum,
  PresetEnum,
  OrderStatus,
} = require("@1inch/cross-chain-sdk");
const { Web3 } = require("web3");
const { randomBytes } = require("crypto");
require("dotenv").config();

function getRandomBytes32() {
  return "0x" + randomBytes(32).toString("hex");
}

const makerPrivateKey = process.env.MAKER_PRIVATE_KEY;
const makerAddress = process.env.MAKER_ADDRESS;
const nodeUrl = process.env.NODE_URL;
const devPortalApiKey = process.env.DEV_PORTAL_API_KEY;

if (!makerPrivateKey || !makerAddress || !nodeUrl || !devPortalApiKey) {
  throw new Error(
    "Missing required environment variables. Please check your .env file."
  );
}

const web3Instance = new Web3(nodeUrl);
const blockchainProvider = new PrivateKeyProviderConnector(
  makerPrivateKey,
  web3Instance
);

const sdk = new SDK({
  url: "https://api.1inch.dev/fusion-plus",
  authKey: devPortalApiKey,
  blockchainProvider,
});

let srcChainId = NetworkEnum.ETHEREUM;
let dstChainId = NetworkEnum.POLYGON;
let srcTokenAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"; // USDC ON ETHEREUM
let dstTokenAddress = "0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39"; // LINK ON POLYGON

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  const usdcContract = new web3Instance.eth.Contract(
    [
      {
        constant: true,
        inputs: [{ name: "_owner", type: "address" }],
        name: "balanceOf",
        outputs: [{ name: "balance", type: "uint256" }],
        type: "function",
      },
    ],
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48" // USDC on Ethereum
  );

  const usdcBalance = await usdcContract.methods.balanceOf(makerAddress).call();
  console.log(`USDC Balance: ${Number(usdcBalance) / 1e6} USDC`);

  const params = {
    srcChainId,
    dstChainId,
    srcTokenAddress,
    dstTokenAddress,
    amount: "1000000000",
    enableEstimate: true,
    walletAddress: makerAddress,
  };

  try {
    const quote = await sdk.getQuote(params);
    console.log("Quote received:", quote);
    await sleep(2000);

    const preset = PresetEnum.fast;
    const secretsCount = quote.presets[preset].secretsCount;

    const secrets = Array.from({ length: secretsCount }).map(() =>
      getRandomBytes32()
    );
    const secretHashes = secrets.map((s) => HashLock.hashSecret(s));

    const hashLock =
      secrets.length === 1
        ? HashLock.forSingleFill(secrets[0])
        : HashLock.forMultipleFills(HashLock.getMerkleLeaves(secrets));

    console.log("Placing order with:", {
      walletAddress: makerAddress,
      hashLock,
      secretHashes,
    });

    const { order, hash, quoteId } = await sdk.createOrder(quote, {
      walletAddress: makerAddress,
      hashLock,
      preset,
      secretHashes,
    });

    console.log("Order created!");

    console.log("Order hash:", hash);

    // console.log(
    //   "Order details:",
    //   JSON.stringify(
    //     order,
    //     (key, value) => (typeof value === "bigint" ? value.toString() : value), // Convert BigInt to string
    //     2
    //   )
    // );

    await sleep(2000);

    try {
      const storedOrder = await sdk.getOrderStatus(hash);
      console.log("🟢 Order found in 1inch backend:", storedOrder);
    } catch (error) {
      console.error(
        "❌ Order not found! Retry order creation without forked chain..."
      );
      return;
    }

    await sleep(2000);
    await sdk.submitOrder(quote.params.srcChain, order, quoteId, secretHashes);
    console.log("Order submitted:", hash);

    const intervalId = setInterval(async () => {
      console.log(
        `Polling for fills until order status is set to "executed"...`
      );
      try {
        const orderStatus = await sdk.getOrderStatus(hash);

        if (
          orderStatus.status === OrderStatus.Executed ||
          orderStatus.status === OrderStatus.Expired ||
          orderStatus.status === OrderStatus.Refunded
        ) {
          console.log(`Order status: ${orderStatus.status}. Exiting.`);
          clearInterval(intervalId);
          return;
        }
      } catch (error) {
        console.error(
          `Error checking order status: ${JSON.stringify(error, null, 2)}`
        );
      }

      try {
        const secretsToShare = await sdk.getReadyToAcceptSecretFills(hash);
        if (secretsToShare.fills.length > 0) {
          for (const { idx } of secretsToShare.fills) {
            await sdk.submitSecret(hash, secrets[idx]);
            console.log(`Shared secret for fill index: ${idx}`);
          }
        }
      } catch (error) {
        console.error(
          `Error submitting secrets: ${JSON.stringify(error, null, 2)}`
        );
      }
    }, 5000);
  } catch (error) {
    // console.dir(error, { depth: null });
    console.error(error);
  }
}

module.exports = { main };

main().catch(console.error);

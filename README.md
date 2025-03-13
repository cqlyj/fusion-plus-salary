1. Import the default anvil key into the wallet(The first address `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`)

```bash
    cast wallet import default --interactive
```

Here I would call it `default`, and a interactive prompt will show as below, the private key is `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`, as for the password, pick a password you like.

```bash
    Enter private key:
    Enter password:
    `default` keystore was saved successfully. Address: address-corresponding-to-private-key
```

Please keep in mind the password you entered, this will be needed for you moving forward with the private key.

3. Now you have the private key stored, and you can check it by running the following command:

```bash
    cast wallet list
```

You will see the `default` in the list.

4. Set up your environment variables:

```bash
cp .env.example .env
```

The only thing missing is the mainnet rpc url, cause for the test, I swap the mainnet USDC to Polygon LINK.

5. Spin up the anvil network with the following command:

```bash
make anvil
```

6. Deploy the contract

```bash
make install
make deploy
```

7. Impersonate some unlucky user who has the USDC

```bash
make impersonate-usdc
```

8. Send some USDC to the `default` address

```bash
make send-usdc
```

9. Now you can deposit and add employees to the contract, This will add the second anvil address `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` as an employee and deposit 10000000000 USDC to contract.

```bash
make add-employee
make deposit-funds
```

10. The second address can set their preferred token and chain id:

```bash
make set-preferences
```

11. Now, let's claim the payroll!

```bash
make claim-payroll
```

You can find in the logs that we have transferred the USDC to the employee address and emitted the event `CrossChainPayrollClaimed`

```bash
 [59424] 0x95D7fF1684a8F2e202097F28Dc2e56F773A55D02::claimPayroll(1)
    ├─ [9839] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::balanceOf(0x95D7fF1684a8F2e202097F28Dc2e56F773A55D02) [staticcall]
    │   ├─ [2553] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::balanceOf(0x95D7fF1684a8F2e202097F28Dc2e56F773A55D02) [delegatecall]
    │   │   └─ ← [Return] 10000000000 [1e10]
    │   └─ ← [Return] 10000000000 [1e10]
    ├─ [15052] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::transfer(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 10000000000 [1e10])
    │   ├─ [14263] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::transfer(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 10000000000 [1e10]) [delegatecall]
    │   │   ├─ emit Transfer(from: 0x95D7fF1684a8F2e202097F28Dc2e56F773A55D02, to: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, value: 10000000000 [1e10])
    │   │   └─ ← [Return] true
    │   └─ ← [Return] true
    ├─ emit CrossChainPayrollClaimed(employeeId: 1, connectedWallet: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, tokens: [0x514910771AF9Ca656af840dff83E8264EcF986CA], percentages: [50], chainId: 137)
    └─ ← [Stop]
```

This event also includes the connected wallet, tokens, percentages, and chain id(destination chain id) which is necessary for the `fusion+` to get quote and build order.

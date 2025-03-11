-include .env

install:
	@forge install OpenZeppelin/openzeppelin-contracts --no-commit

anvil:
	@anvil --fork-url $(MAINNET_RPC_URL) 

deploy:
	@forge script script/DeployPayroll.s.sol:DeployPayroll --rpc-url $(ANVIL_RPC_URL) --account default --sender $(DEFAULT_USER) --broadcast -vvvv

deposit-funds:
	@forge script script/DepositFunds.s.sol:DepositFunds --rpc-url $(ANVIL_RPC_URL) --account default --sender $(DEFAULT_USER) --broadcast -vvvv

add-employee:
	@forge script script/AddEmployee.s.sol:AddEmployee --rpc-url $(ANVIL_RPC_URL) --account default --sender $(DEFAULT_USER) --broadcast -vvvv

set-token-preferences:
	@forge script script/SetTokenPreferences.s.sol:SetTokenPreferences --rpc-url $(ANVIL_RPC_URL) --private-key $(SECOND_USER_PRIVATE_KEY) --broadcast -vvvv

balanceOf-link-unlucky:
	@cast call $(MAINNET_LINK_ADDRESS) "balanceOf(address)(uint256)" $(UNLUCKY_USER_LINK) 0

balanceOf-usdc-unlucky:
	@cast call $(MAINNET_LINK_ADDRESS) "balanceOf(address)(uint256)" $(UNLUCKY_USER_USDC) 0

balanceOf-link-default:
	@cast call $(MAINNET_LINK_ADDRESS) "balanceOf(address)(uint256)" $(DEFAULT_USER) 0	

balanceOf-usdc-default:
	@cast call $(MAINNET_USDC_ADDRESS) "balanceOf(address)(uint256)" $(DEFAULT_USER) 0

impersonate-link:
	@cast rpc anvil_impersonateAccount $(UNLUCKY_USER_LINK)

impersonate-usdc:
	@cast rpc anvil_impersonateAccount $(UNLUCKY_USER_USDC)

send-link:
	@cast send $(MAINNET_LINK_ADDRESS) --from $(UNLUCKY_USER_LINK) "transfer(address,uint256)(bool)" $(DEFAULT_USER) 1000000000000000000 --unlocked

send-usdc:
	@cast send $(MAINNET_USDC_ADDRESS) --from $(UNLUCKY_USER_USDC) "transfer(address,uint256)(bool)" $(DEFAULT_USER) 10000000000 --unlocked
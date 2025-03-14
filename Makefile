-include .env

install:
	@forge install OpenZeppelin/openzeppelin-contracts --no-commit && forge install 1inch/cross-chain-swap --no-commit && forge install 1inch/limit-order-protocol --no-commit

anvil-src:
	@anvil --fork-url $(MAINNET_RPC_URL) 

anvil-dst:
	@anvil --fork-url $(POLYGON_RPC_URL) -p 8544

############################################################################################
#                                     Deploy contracts                                     #
############################################################################################

deploy-payroll:
	@forge script script/DeployPayroll.s.sol:DeployPayroll --rpc-url $(ANVIL_RPC_URL_SRC) --account default --sender $(DEFAULT_USER) --broadcast -vvvv

deploy-mock-resolver-src:
	@forge script script/1inch/DeployMockResolver.s.sol:DeployMockResolver --rpc-url $(ANVIL_RPC_URL_SRC) --account default --sender $(DEFAULT_USER) --broadcast -vvvv

deploy-mock-resolver-dst:
	@forge script script/1inch/DeployMockResolver.s.sol:DeployMockResolver --rpc-url $(ANVIL_RPC_URL_DST) --account default --sender $(DEFAULT_USER) --broadcast -vvvv

############################################################################################
#                                     Call functions                                       #
############################################################################################

deposit-funds:
	@forge script script/DepositFunds.s.sol:DepositFunds --rpc-url $(ANVIL_RPC_URL_SRC) --account default --sender $(DEFAULT_USER) --broadcast -vvvv

add-employee:
	@forge script script/AddEmployee.s.sol:AddEmployee --rpc-url $(ANVIL_RPC_URL_SRC) --account default --sender $(DEFAULT_USER) --broadcast -vvvv

set-preferences:
	@forge script script/SetPreferences.s.sol:SetPreferences --rpc-url $(ANVIL_RPC_URL_SRC) --private-key $(SECOND_USER_PRIVATE_KEY) --broadcast -vvvv

claim-payroll:
	@forge script script/ClaimPayroll.s.sol:ClaimPayroll --rpc-url $(ANVIL_RPC_URL_SRC) --private-key $(SECOND_USER_PRIVATE_KEY) --broadcast -vvvv

deploy-src:
	@forge script script/1inch/DeploySrc.s.sol:DeploySrc --rpc-url $(ANVIL_RPC_URL_SRC) --account default --sender $(DEFAULT_USER) --broadcast -vvvv

############################################################################################
#                                      Simulations										   #
############################################################################################

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
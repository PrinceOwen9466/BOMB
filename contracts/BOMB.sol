// SPDX-License-Identifier: MIT
/*
 __    ____     _____            ____
/\ \_ /\  _`\  /\  __`\  /'\_/`\/\  _`\
\/'__`\ \ \L\ \\ \ \/\ \/\      \ \ \L\ \
/\ \_\_\ \  _ <'\ \ \ \ \ \ \__\ \ \  _ <'
\ \____ \ \ \L\ \\ \ \_\ \ \ \_/\ \ \ \L\ \
 \/\ \_\ \ \____/ \ \_____\ \_\\ \_\ \____/
  \ `\_ _/\/___/   \/_____/\/_/ \/_/\/___/
   `\_/\_\
      \/_/
*/

pragma solidity ^0.8.24;

import "./BOMBBase.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeMathInt.sol";

contract BOMB is BOMBBase {
	using SafeMath for uint256;
	using SafeMathInt for int256;

	mapping(address => mapping(address => uint256)) private _allowedFragments;

	constructor() {
		_isFeeExempt[treasuryReceiver] = true;
		_isFeeExempt[address(this)] = true;

		_transferOwnership(treasuryReceiver);
		emit Transfer(address(0x0), treasuryReceiver, _totalSupply);
	}

	receive() external payable {}

	function checkFeeExempt(address _addr) external view returns (bool) {
		return _isFeeExempt[_addr];
	}

	function getCirculatingSupply() public view returns (uint256) {
		return (TOTAL_GONS.sub(_gonBalances[ADDR_DEAD]).sub(_gonBalances[address(0)])).div(_gonsPerFragment);
	}

	function isNotInSwap() external view returns (bool) {
		return !_inSwap;
	}

	function manualSync() external {
		IPancakeSwapPair(_pairAddr).sync();
	}

	function totalSupply() external view override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address who) external view override returns (uint256) {
		return _gonBalances[who].div(_gonsPerFragment);
	}

	function approve(address spender, uint256 value) external override returns (bool) {
		_allowedFragments[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

	function transfer(address to, uint256 value) external override validRecipient(to) returns (bool) {
		_transferFrom(msg.sender, to, value);
		return true;
	}

	function transferFrom(address from, address to, uint256 value) external override validRecipient(to) returns (bool) {
		// TODO: Super important, review this line
		if (_allowedFragments[from][msg.sender] != uint256(int256(-1))) {
			_allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value, "Insufficient Allowance");
		}
		_transferFrom(from, to, value);
		return true;
	}

	function allowance(address owner_, address spender) external view override returns (uint256) {
		return _allowedFragments[owner_][spender];
	}

	function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
		_allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender].add(addedValue);
		emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
		uint256 oldValue = _allowedFragments[msg.sender][spender];
		if (subtractedValue >= oldValue) {
			_allowedFragments[msg.sender][spender] = 0;
		} else {
			_allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
		}
		emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
		return true;
	}

	function _basicTransfer(address from, address to, uint256 amount) internal returns (bool) {
		uint256 gonAmount = amount.mul(_gonsPerFragment);
		_gonBalances[from] = _gonBalances[from].sub(gonAmount);
		_gonBalances[to] = _gonBalances[to].add(gonAmount);
		return true;
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(!_blacklist[sender] && !_blacklist[recipient], "in_blacklist");

		if (_inSwap) {
			return _basicTransfer(sender, recipient, amount);
		}
		if (shouldRebase()) {
			rebase();
		}

		if (shouldAddLiquidity()) {
			addLiquidity();
		}

		if (shouldSwapBack()) {
			swapBack();
		}

		uint256 gonAmount = amount.mul(_gonsPerFragment);
		_gonBalances[sender] = _gonBalances[sender].sub(gonAmount);
		uint256 gonAmountReceived = shouldTakeFee(sender, recipient) ? _takeFee(sender, recipient, gonAmount) : gonAmount;
		_gonBalances[recipient] = _gonBalances[recipient].add(gonAmountReceived);

		emit Transfer(sender, recipient, gonAmountReceived.div(_gonsPerFragment));
		return true;
	}

	function _takeFee(address sender, address recipient, uint256 gonAmount) internal returns (uint256) {
		uint256 _totalFee = totalFee;
		uint256 _treasuryFee = treasuryFee;

		if (recipient == _pairAddr) {
			_totalFee = totalFee.add(sellFee);
			_treasuryFee = treasuryFee.add(sellFee);
		}

		uint256 feeAmount = gonAmount.div(feeDenominator).mul(_totalFee);

		_gonBalances[firePit] = _gonBalances[firePit].add(gonAmount.div(feeDenominator).mul(firePitFee));
		_gonBalances[address(this)] = _gonBalances[address(this)].add(gonAmount.div(feeDenominator).mul(_treasuryFee.add(safuuInsuranceFundFee)));
		_gonBalances[autoLiquidityReceiver] = _gonBalances[autoLiquidityReceiver].add(gonAmount.div(feeDenominator).mul(liquidityFee));

		emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));
		return gonAmount.sub(feeAmount);
	}

	function addLiquidity() internal swapping {
		uint256 autoLiquidityAmount = _gonBalances[autoLiquidityReceiver].div(_gonsPerFragment);
		_gonBalances[address(this)] = _gonBalances[address(this)].add(_gonBalances[autoLiquidityReceiver]);
		_gonBalances[autoLiquidityReceiver] = 0;
		uint256 amountToLiquify = autoLiquidityAmount.div(2);
		uint256 amountToSwap = autoLiquidityAmount.sub(amountToLiquify);

		if (amountToSwap == 0) {
			return;
		}
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _router.WETH();

		uint256 balanceBefore = address(this).balance;

		_router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);

		uint256 amountETHLiquidity = address(this).balance.sub(balanceBefore);

		if (amountToLiquify > 0 && amountETHLiquidity > 0) {
			_router.addLiquidityETH{value: amountETHLiquidity}(address(this), amountToLiquify, 0, 0, autoLiquidityReceiver, block.timestamp);
		}
		_lastAddLiquidityTime = block.timestamp;
	}

	function swapBack() internal swapping {
		uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);

		if (amountToSwap == 0) {
			return;
		}

		uint256 balanceBefore = address(this).balance;
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _router.WETH();

		_router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);

		uint256 amountETHToTreasuryAndSIF = address(this).balance.sub(balanceBefore);

		(bool success, ) = payable(treasuryReceiver).call{
			value: amountETHToTreasuryAndSIF.mul(treasuryFee).div(treasuryFee.add(safuuInsuranceFundFee)),
			gas: 30000
		}("");
		(success, ) = payable(safuuInsuranceFundReceiver).call{
			value: amountETHToTreasuryAndSIF.mul(safuuInsuranceFundFee).div(treasuryFee.add(safuuInsuranceFundFee)),
			gas: 30000
		}("");
	}

	function rebase() internal {
		if (_inSwap) return;
		uint256 rebaseRate;
		uint256 deltaTimeFromInit = block.timestamp - _initRebaseStartTime;
		uint256 deltaTime = block.timestamp - _lastRebasedTime;
		uint256 times = deltaTime.div(15 minutes);
		uint256 epoch = times.mul(15);

		if (deltaTimeFromInit < (365 days)) {
			rebaseRate = 2355;
		} else if (deltaTimeFromInit >= (365 days)) {
			rebaseRate = 211;
		} else if (deltaTimeFromInit >= ((15 * 365 days) / 10)) {
			rebaseRate = 14;
		} else if (deltaTimeFromInit >= (7 * 365 days)) {
			rebaseRate = 2;
		}

		for (uint256 i = 0; i < times; i++) {
			_totalSupply = _totalSupply.mul((10 ** RATE_DECIMALS).add(rebaseRate)).div(10 ** RATE_DECIMALS);
		}

		_gonsPerFragment = TOTAL_GONS.div(_totalSupply);
		_lastRebasedTime = _lastRebasedTime.add(times.mul(15 minutes));

		_pair.sync();

		emit LogRebase(epoch, _totalSupply);
	}
}

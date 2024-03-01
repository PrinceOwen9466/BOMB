// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./BOMBBase.sol";
import "./NativeTransferable.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeMathInt.sol";

contract BOMB is BOMBBase, NativeTransferable {
	using SafeMath for uint256;
	using SafeMathInt for int256;

	mapping(address => mapping(address => uint256)) private _allowance;

	receive() external payable {}

	function checkFeeExempt(address _addr) external view returns (bool) {
		return _isFeeExempt[_addr];
	}

	function isNotInSwap() external view returns (bool) {
		return !_inSwap;
	}

	function manualSync() external {
		IPancakeSwapPair(address(_pair)).sync();
	}

	function manualSwapBack() external onlyOwner {
		_trySwapBack();
	}

	function manualDistribute() external onlyOwner {
		_distributeWNative();
	}

	function totalSupply() external view override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address who) external view override returns (uint256) {
		return _balances[who];
	}

	function approve(address spender, uint256 value) external override returns (bool) {
		_allowance[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);

		return true;
	}

	function transfer(address to, uint256 value) external override validRecipient(to) returns (bool) {
		_transferFrom(msg.sender, to, value);
		return true;
	}

	function transferFrom(address from, address to, uint256 value) external override validRecipient(to) returns (bool) {
		if (from == address(this) && to == address(_router)) {
			return true;
		}

		_allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value, "Insufficient Allowance");
		_transferFrom(from, to, value);
		return true;
	}

	function allowance(address owner_, address spender) external view override returns (uint256) {
		return _allowance[owner_][spender];
	}

	function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
		_allowance[msg.sender][spender] = _allowance[msg.sender][spender].add(addedValue);
		emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
		uint256 oldValue = _allowance[msg.sender][spender];
		if (subtractedValue >= oldValue) {
			_allowance[msg.sender][spender] = 0;
		} else {
			_allowance[msg.sender][spender] = oldValue.sub(subtractedValue);
		}
		emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
		return true;
	}

	function _basicTransfer(address from, address to, uint256 amount) internal returns (bool) {
		_subBalance(from, amount);
		_addBalance(to, amount);
		return true;
	}

	function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
		require(!_blacklist[from] && !_blacklist[to], "in_blacklist");

		if (_inSwap) {
			return _basicTransfer(from, to, amount);
		}

		bool isBuy = from == address(_pair);
		bool isSell = to == address(_pair);

		if (shouldRebase()) {
			_rebase();
		}

		if (shouldSwapBack()) {
			bool canSwap = !(isBuy || isSell); // Swap on normal transfers
			canSwap = canSwap || (_swapOnBuys && isBuy);
			canSwap = canSwap || (_swapOnSells && isSell);

			if (canSwap) {
				_trySwapBack();
			}
		}

		if (shouldDistribute()) {
			_distributeWNative();
		}

		_subBalance(from, amount);

		uint256 amountReceived = shouldTakeFee(from, to) ? _takeFee(from, amount) : amount;
		_addBalance(to, amountReceived);

		emit Transfer(from, to, amountReceived);

		return true;
	}

	function _takeFee(address sender, uint256 amount) internal returns (uint256) {
		uint256 feeAmount = amount.div(100).mul(_taxPercentage);
		_addBalance(address(this), feeAmount);
		emit Transfer(sender, address(this), feeAmount);

		return amount.sub(feeAmount);
	}

	function _distributeNative(uint256 amount) internal {
		if (amount <= 0) {
			return;
		}

		address holder;
		uint256 cut;

		for (uint i = 0; i < _holders.length; i++) {
			holder = _holders[i];

			if (!_isExternalAddr(holder)) {
				continue;
			}

			cut = amount.mul(_balances[holder]).div(_totalSupply);

			if (cut > 0) {
				_transferNative(holder, cut);
			}
		}
	}

	function _distributeWNative() internal {
		if (address(_WNative) == address(0)) {
			return;
		}

		uint256 amount = _WNative.balanceOf(address(this));
		if (amount <= 0) {
			return;
		}

		address holder;
		uint256 cut;

		for (uint i = 0; i < _holders.length; i++) {
			holder = _holders[i];

			if (!_isExternalAddr(holder)) {
				continue;
			}

			cut = amount.mul(_balances[holder]).div(_totalSupply);

			if (cut > 0) {
				if (_WNative.transfer(holder, cut)) {
					emit WrappedTransfer(holder, cut);
				}
			}
		}

		_lastDistribution = block.timestamp;
	}

	function _distribute() internal {
		uint256 amount = _balances[address(this)];

		if (amount <= 0) {
			return;
		}

		_subBalance(address(this), amount);

		address holder;

		uint256 cut;
		uint256 distributed;

		for (uint i = 0; i < _holders.length; i++) {
			holder = _holders[i];

			if (!_isExternalAddr(holder)) {
				continue;
			}

			cut = amount.mul(_balances[holder]).div(_totalSupply);
			distributed += cut;

			if (cut > 0) {
				_addBalance(holder, cut);
				emit Transfer(address(this), holder, cut);
			}
		}

		uint256 rem = amount - distributed;
		_addBalance(address(this), rem);
	}

	function _rebase() internal {
		if (_inSwap) return;
		uint256 rebaseRate;
		uint256 deltaTimeFromInit = block.timestamp - _initRebaseStartTime;
		uint256 deltaTime = block.timestamp - _lastRebasedTime;
		uint256 times = deltaTime.div(REBASE_INTERVAL);
		uint256 epoch = times.mul(15); // TODO: Probably update this with any time change

		if (deltaTimeFromInit > (3 * 365 days)) {
			rebaseRate = 1;
		} else if (deltaTimeFromInit >= (2 * 365 days)) {
			rebaseRate = 19;
		} else if (deltaTimeFromInit >= 365 days) {
			rebaseRate = 191;
		} else {
			rebaseRate = 1915;
		}

		uint256 supply = _totalSupply;

		for (uint256 i = 0; i < times; i++) {
			supply = _totalSupply.mul((10 ** RATE_DECIMALS).add(rebaseRate)).div(10 ** RATE_DECIMALS);
		}

		_lastRebasedTime = _lastRebasedTime.add(times.mul(REBASE_INTERVAL));

		try _pair.sync() {} catch {}

		_addBalance(address(this), supply - _totalSupply);
		_distribute();

		_totalSupply = supply;
		emit LogRebase(epoch, _totalSupply);
	}

	function _trySwapBack() private swapping {
		uint256 swapAmount = _balances[address(this)];

		if (swapAmount < _swapThreshold) {
			return;
		}

		// TODO: Add lp price calculations
		if (swapAmount > _swapAmount) {
			swapAmount = _swapAmount;
		}

		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = address(_WNative);

		try _router.swapExactTokensForETHSupportingFeeOnTransferTokens(swapAmount, 0, path, address(this), block.timestamp) {} catch {
			return;
		}

		emit LogSwapBack(swapAmount);
	}

	function blastFeesClaimed(uint256 value) internal virtual override {
		_distributeNative(value);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Ownable.sol";
import "./ERC20Detailed.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/PancakeSwap.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeMathInt.sol";

abstract contract BOMBBase is ERC20Detailed, Ownable {
	using SafeMath for uint256;
	using SafeMathInt for int256;

	string private constant NAME = "BOMB";
	string private constant SYM = "BOMB";
	uint8 private constant DECIMALS = 5;
	uint8 internal constant RATE_DECIMALS = 7;

	uint256 private constant MAX_UINT256 = ~uint256(0);
	uint256 private constant MAX_SUPPLY = 325 * 10 ** 7 * 10 ** DECIMALS;
	uint256 private constant INITIAL_SUPPLY = 325 * 10 ** 3 * 10 ** DECIMALS;

	address private constant ADDR_ROUTER = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;
	address private constant ADDR_FACTORY = 0xF5c7d9733e5f53abCC1695820c4818C59B457C2C;
	address internal constant ADDR_DEAD = 0x000000000000000000000000000000000000dEaD;

	uint256 public _feePercent = 99;
	uint256 public _distributionInterval = 10 minutes;

	bool public _autoRebase;

	uint256 public _initRebaseStartTime;
	uint256 public _lastRebasedTime;
	uint256 public _totalSupply;

	uint256 internal _lastDistribution;

	mapping(address => uint256) internal _balances;
	mapping(address => bool) private _isHolder;
	mapping(address => bool) internal _isFeeExempt;
	mapping(address => bool) public _blacklist;
	address[] internal _holders;

	IPancakeSwapRouter internal _router;
	IPancakeSwapPair internal _pair;

	bool internal _inSwap = false;
	modifier swapping() {
		_inSwap = true;
		_;
		_inSwap = false;
	}

	modifier validRecipient(address to) {
		require(to != address(0x0));
		_;
	}

	constructor() ERC20Detailed(NAME, SYM, DECIMALS) Ownable() {
		_totalSupply = INITIAL_SUPPLY;
		_initRebaseStartTime = block.timestamp;
		_lastRebasedTime = block.timestamp;
		_autoRebase = true;
		_isFeeExempt[address(this)] = true;

		_router = IPancakeSwapRouter(ADDR_ROUTER);

		_balances[msg.sender] = _totalSupply;
		emit Transfer(address(this), msg.sender, _totalSupply);
	}

	function _isExternalAddr(address addr) internal view returns (bool) {
		return addr != address(this) && addr != address(_pair);
	}

	function _addBalance(address addr, uint256 sum) internal {
		_setBalance(addr, _balances[addr].add(sum));
	}

	function _subBalance(address addr, uint256 diff) internal {
		_setBalance(addr, _balances[addr].sub(diff));
	}

	function _setBalance(address addr, uint256 balance) internal {
		// LP and Contract cannot be holders
		if (_isExternalAddr(addr)) {
			if (_isHolder[addr] != true) {
				_holders.push(addr);
				_isHolder[addr] = true;
			}
		}

		_balances[addr] = balance;
	}

	function setAutoRebase(bool _flag) external onlyOwner {
		if (_flag) {
			_autoRebase = _flag;
			_lastRebasedTime = block.timestamp;
		} else {
			_autoRebase = _flag;
		}
	}

	function setWhitelist(address _addr) external onlyOwner {
		_isFeeExempt[_addr] = true;
	}

	function setBotBlacklist(address _botAddress, bool _flag) external onlyOwner {
		require(isContract(_botAddress), "only contract address, not allowed exteranlly owned account");
		_blacklist[_botAddress] = _flag;
	}

	function setFeePercentage(uint256 percent) external onlyOwner {
		_feePercent = percent;
	}

	function isContract(address addr) internal view returns (bool) {
		uint size;
		assembly {
			size := extcodesize(addr)
		}
		return size > 0;
	}

	function shouldTakeFee(address from, address to) internal view returns (bool) {
		return (address(_pair) == from || address(_pair) == to) && !_isFeeExempt[from];
	}

	function shouldRebase() internal view returns (bool) {
		return _autoRebase && (_totalSupply < MAX_SUPPLY) && msg.sender != address(_pair) && !_inSwap && block.timestamp >= (_lastRebasedTime + 15 minutes);
	}

	function shouldDistribute() internal view returns (bool) {
		return _balances[address(this)] > 0 && block.timestamp >= _lastDistribution + _distributionInterval;
	}

	function setLP(address addr) external onlyOwner {
		_pair = IPancakeSwapPair(addr);
	}

	function setDistributeInterval(uint256 interval) external onlyOwner {
		_distributionInterval = interval;
	}

	event LogRebase(uint256 indexed epoch, uint256 totalSupply);
}

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
	uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 325 * 10 ** 3 * 10 ** DECIMALS;
	uint256 internal constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

	address private constant ADDR_ROUTER = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;
	address private constant ADDR_FACTORY = 0xF5c7d9733e5f53abCC1695820c4818C59B457C2C;
	address internal constant ADDR_DEAD = 0x000000000000000000000000000000000000dEaD;

	// TODO: Define defaults for these fields
	address public autoLiquidityReceiver;
	address public treasuryReceiver;
	address public safuuInsuranceFundReceiver;
	address public firePit;
	address public pairAddress;

	uint256 public liquidityFee = 40;
	uint256 public treasuryFee = 25;
	uint256 public safuuInsuranceFundFee = 50;
	uint256 public sellFee = 20;
	uint256 public firePitFee = 25;
	uint256 public totalFee = liquidityFee.add(treasuryFee).add(safuuInsuranceFundFee).add(firePitFee);
	uint256 public feeDenominator = 1000;

	bool public _autoRebase;
	bool public _autoAddLiquidity;
	address internal _pairAddr;
	uint256 public _initRebaseStartTime;
	uint256 public _lastRebasedTime;
	uint256 public _lastAddLiquidityTime;
	uint256 public _totalSupply;
	uint256 internal _gonsPerFragment;

	mapping(address => uint256) internal _gonBalances;
	mapping(address => bool) internal _isFeeExempt;
	mapping(address => bool) public _blacklist;

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
		_router = IPancakeSwapRouter(ADDR_ROUTER);
		_pairAddr = IPancakeSwapFactory(_router.factory()).createPair(_router.WETH(), address(this));
		_pair = IPancakeSwapPair(_pairAddr);

		_totalSupply = INITIAL_FRAGMENTS_SUPPLY;
		_gonBalances[treasuryReceiver] = TOTAL_GONS;
		_gonsPerFragment = TOTAL_GONS.div(_totalSupply);
		_initRebaseStartTime = block.timestamp;
		_lastRebasedTime = block.timestamp;
		_autoRebase = true;
		_autoAddLiquidity = true;
		_isFeeExempt[treasuryReceiver] = true;
		_isFeeExempt[address(this)] = true;
	}

	function setAutoRebase(bool _flag) external onlyOwner {
		if (_flag) {
			_autoRebase = _flag;
			_lastRebasedTime = block.timestamp;
		} else {
			_autoRebase = _flag;
		}
	}

	function setAutoAddLiquidity(bool _flag) external onlyOwner {
		if (_flag) {
			_autoAddLiquidity = _flag;
			_lastAddLiquidityTime = block.timestamp;
		} else {
			_autoAddLiquidity = _flag;
		}
	}

	function withdrawAllToTreasury() external swapping onlyOwner {
		uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);
		require(amountToSwap > 0, "There is no Safuu token deposited in token contract");
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _router.WETH();
		_router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, treasuryReceiver, block.timestamp);
	}

	function setWhitelist(address _addr) external onlyOwner {
		_isFeeExempt[_addr] = true;
	}

	function setBotBlacklist(address _botAddress, bool _flag) external onlyOwner {
		require(isContract(_botAddress), "only contract address, not allowed exteranlly owned account");
		_blacklist[_botAddress] = _flag;
	}

	function setPairAddress(address _pairAddress) public onlyOwner {
		pairAddress = _pairAddress;
	}

	function setFeeReceivers(
		address _autoLiquidityReceiver,
		address _treasuryReceiver,
		address _safuuInsuranceFundReceiver,
		address _firePit
	) external onlyOwner {
		autoLiquidityReceiver = _autoLiquidityReceiver;
		treasuryReceiver = _treasuryReceiver;
		safuuInsuranceFundReceiver = _safuuInsuranceFundReceiver;
		firePit = _firePit;
	}

	function isContract(address addr) internal view returns (bool) {
		uint size;
		assembly {
			size := extcodesize(addr)
		}
		return size > 0;
	}

	function shouldTakeFee(address from, address to) internal view returns (bool) {
		return (_pairAddr == from || _pairAddr == to) && !_isFeeExempt[from];
	}

	function shouldRebase() internal view returns (bool) {
		return _autoRebase && (_totalSupply < MAX_SUPPLY) && msg.sender != _pairAddr && !_inSwap && block.timestamp >= (_lastRebasedTime + 15 minutes);
	}

	function shouldAddLiquidity() internal view returns (bool) {
		return _autoAddLiquidity && !_inSwap && msg.sender != _pairAddr && block.timestamp >= (_lastAddLiquidityTime + 2 days);
	}

	function shouldSwapBack() internal view returns (bool) {
		return !_inSwap && msg.sender != _pairAddr;
	}

	event LogRebase(uint256 indexed epoch, uint256 totalSupply);
}

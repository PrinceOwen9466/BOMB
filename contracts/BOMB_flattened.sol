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
// File: contracts/NativeTransferable.sol


pragma solidity ^0.8.24;

abstract contract NativeTransferable {
	function _transferNative(address to, uint256 amount) internal returns (bool) {
		if (payable(to).send(amount)) {
			return true;
		}

		return false;
	}

	event NativeTransfer(address recipient, uint256 amount);
}

// File: contracts/libraries/SafeMathInt.sol


pragma solidity ^0.8.24;

library SafeMathInt {
	int256 private constant MIN_INT256 = int256(1) << 255;
	int256 private constant MAX_INT256 = ~(int256(1) << 255);

	function mul(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a * b;

		require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
		require((b == 0) || (c / b == a));
		return c;
	}

	function div(int256 a, int256 b) internal pure returns (int256) {
		require(b != -1 || a != MIN_INT256);

		return a / b;
	}

	function sub(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a - b;
		require((b >= 0 && c <= a) || (b < 0 && c > a));
		return c;
	}

	function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a));
		return c;
	}

	function abs(int256 a) internal pure returns (int256) {
		require(a != MIN_INT256);
		return a < 0 ? -a : a;
	}
}

// File: contracts/libraries/SafeMath.sol


pragma solidity ^0.8.24;

library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			uint256 c = a + b;
			if (c < a) return (false, 0);
			return (true, c);
		}
	}

	/**
	 * @dev Returns the substraction of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b > a) return (false, 0);
			return (true, a - b);
		}
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
			// benefit is lost if 'b' is also tested.
			// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
			if (a == 0) return (true, 0);
			uint256 c = a * b;
			if (c / a != b) return (false, 0);
			return (true, c);
		}
	}

	/**
	 * @dev Returns the division of two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a / b);
		}
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a % b);
		}
	}

	/**
	 * @dev Returns the addition of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
	 *
	 * - Addition cannot overflow.
	 */
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		return a + b;
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return a - b;
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `*` operator.
	 *
	 * Requirements:
	 *
	 * - Multiplication cannot overflow.
	 */
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		return a * b;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator.
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * reverting when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return a % b;
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
	 *
	 * CAUTION: This function is deprecated because it requires allocating memory for the error
	 * message unnecessarily. For custom revert reasons use {trySub}.
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		unchecked {
			require(b <= a, errorMessage);
			return a - b;
		}
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting with custom message on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a / b;
		}
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * reverting with custom message when dividing by zero.
	 *
	 * CAUTION: This function is deprecated because it requires allocating memory for the error
	 * message unnecessarily. For custom revert reasons use {tryMod}.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a % b;
		}
	}
}

// File: contracts/interfaces/PancakeSwap.sol


pragma solidity ^0.8.24;

interface IPancakeSwapPair {
	event Approval(address indexed owner, address indexed spender, uint value);
	event Transfer(address indexed from, address indexed to, uint value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint);

	function balanceOf(address owner) external view returns (uint);

	function allowance(address owner, address spender) external view returns (uint);

	function approve(address spender, uint value) external returns (bool);

	function transfer(address to, uint value) external returns (bool);

	function transferFrom(address from, address to, uint value) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint);

	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

	event Mint(address indexed sender, uint amount0, uint amount1);
	event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
	event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
	event Sync(uint112 reserve0, uint112 reserve1);

	function MINIMUM_LIQUIDITY() external pure returns (uint);

	function factory() external view returns (address);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

	function price0CumulativeLast() external view returns (uint);

	function price1CumulativeLast() external view returns (uint);

	function kLast() external view returns (uint);

	function mint(address to) external returns (uint liquidity);

	function burn(address to) external returns (uint amount0, uint amount1);

	function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

	function skim(address to) external;

	function sync() external;

	function initialize(address, address) external;
}

interface IPancakeSwapRouter {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint amountADesired,
		uint amountBDesired,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline
	) external returns (uint amountA, uint amountB, uint liquidity);

	function addLiquidityETH(
		address token,
		uint amountTokenDesired,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external payable returns (uint amountToken, uint amountETH, uint liquidity);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint liquidity,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline
	) external returns (uint amountA, uint amountB);

	function removeLiquidityETH(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external returns (uint amountToken, uint amountETH);

	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint liquidity,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint amountA, uint amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint amountToken, uint amountETH);

	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

	function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

	function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

	function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

	function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

	function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

	function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

	function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

	function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

	function removeLiquidityETHSupportingFeeOnTransferTokens(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external returns (uint amountETH);

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint amountETH);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IPancakeSwapFactory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint);

	function feeTo() external view returns (address);

	function feeToSetter() external view returns (address);

	function getPair(address tokenA, address tokenB) external view returns (address pair);

	function allPairs(uint) external view returns (address pair);

	function allPairsLength() external view returns (uint);

	function createPair(address tokenA, address tokenB) external returns (address pair);

	function setFeeTo(address) external;

	function setFeeToSetter(address) external;
}

// File: contracts/interfaces/IERC20.sol


pragma solidity ^0.8.24;

interface IERC20 {
	/**
	 * @dev Emitted when `value` tokens are moved from one account (`from`) to
	 * another (`to`).
	 *
	 * Note that `value` may be zero.
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Emitted when the allowance of a `spender` for an `owner` is set by
	 * a call to {approve}. `value` is the new allowance.
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);

	/**
	 * @dev OPTIONAL Returns the name of the token
	 */
	function name() external view returns (string memory);

	/**
	 * @dev OPTIONAL Returns the symbol of the token
	 */
	function symbol() external view returns (string memory);

	/**
	 * @dev OPTIONAL Returns the amount of decimals supported by the token
	 */
	function decimals() external view returns (uint8);

	/**
	 * @dev Returns the value of tokens in existence.
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Returns the value of tokens owned by `account`.
	 */
	function balanceOf(address account) external view returns (uint256);

	/**
	 * @dev Moves a `value` amount of tokens from the caller's account to `to`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transfer(address to, uint256 value) external returns (bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender) external view returns (uint256);

	/**
	 * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
	 * caller's tokens.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * IMPORTANT: Beware that changing an allowance with this method brings the risk
	 * that someone may use both the old and the new allowance by unfortunate
	 * transaction ordering. One possible solution to mitigate this race
	 * condition is to first reduce the spender's allowance to 0 and set the
	 * desired value afterwards:
	 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	 *
	 * Emits an {Approval} event.
	 */
	function approve(address spender, uint256 value) external returns (bool);

	/**
	 * @dev Moves a `value` amount of tokens from `from` to `to` using the
	 * allowance mechanism. `value` is then deducted from the caller's
	 * allowance.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: contracts/ERC20Detailed.sol


pragma solidity ^0.8.24;


abstract contract ERC20Detailed is IERC20 {
	string private _name;
	string private _symbol;
	uint8 private _decimals;

	constructor(string memory name_, string memory symbol_, uint8 decimals_) {
		_name = name_;
		_symbol = symbol_;
		_decimals = decimals_;
	}

	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function decimals() public view returns (uint8) {
		return _decimals;
	}
}

// File: contracts/Ownable.sol


pragma solidity ^0.8.24;

contract Ownable {
	address private _owner;

	event OwnershipRenounced(address indexed previousOwner);

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		_owner = msg.sender;
	}

	function owner() public view returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(isOwner());
		_;
	}

	function isOwner() public view returns (bool) {
		return msg.sender == _owner;
	}

	function renounceOwnership() public onlyOwner {
		emit OwnershipRenounced(_owner);
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public onlyOwner {
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal {
		require(newOwner != address(0));
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

// File: contracts/BlastClaimable.sol


pragma solidity ^0.8.24;


interface IBlast {
	function configureClaimableGas() external;

	function claimAllGas(address contractAddress, address recipient) external returns (uint256);
}

abstract contract BlastClaimable is Ownable {
	IBlast public BLAST;
	mapping(address => uint256) _lastBlastClaim;

	uint256 public _blastClaimInterval = 1 days;
	uint256 internal _feesClaimed;

	function claimMyGasFees() external {
		address recipient = msg.sender;
		uint256 lastClaim = _lastBlastClaim[recipient];

		if (lastClaim + _blastClaimInterval < block.timestamp) {
			return;
		}

		_lastBlastClaim[recipient] = block.timestamp;
		uint256 claimed = BLAST.claimAllGas(address(this), recipient);

		if (claimed > 0) {
			_feesClaimed += claimed;
			blastFeesClaimed(claimed);
		}
	}

	function setupBlast(address blastAddr) external onlyOwner {
		if (blastAddr == address(0)) {
			blastAddr = 0x4300000000000000000000000000000000000002;
		}
		BLAST = IBlast(blastAddr);
		BLAST.configureClaimableGas();
	}

	function setBlastClaimInterval(uint256 interval) external onlyOwner {
		_blastClaimInterval = interval;
	}

	function blastFeesClaimed(uint256 value) internal virtual;
}

// File: contracts/BOMBBase.sol


pragma solidity ^0.8.24;







abstract contract BOMBBase is ERC20Detailed, BlastClaimable {
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
	bool public _autoSwapBack;
	bool public _autoDistribute;

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
		_autoSwapBack = true;
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

	function setAutoSwapBack(bool _flag) external onlyOwner {
		if (_flag) {
			_autoSwapBack = _flag;
		} else {
			_autoSwapBack = _flag;
		}
	}

	function setAutoDistribute(bool _flag) external onlyOwner {
		if (_flag) {
			_autoDistribute = _flag;
		} else {
			_autoDistribute = _flag;
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

	function shouldSwapBack() internal view returns (bool) {
		return _autoSwapBack && !_inSwap && msg.sender != address(_pair);
	}

	function shouldDistribute() internal view returns (bool) {
		return _autoDistribute && block.timestamp >= _lastDistribution + _distributionInterval;
	}

	function setLP(address addr) external onlyOwner {
		_pair = IPancakeSwapPair(addr);
	}

	function setDistributeInterval(uint256 interval) external onlyOwner {
		_distributionInterval = interval;
	}

	event LogRebase(uint256 indexed epoch, uint256 totalSupply);
}

// File: contracts/BOMB.sol


pragma solidity ^0.8.24;





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

	function pairAddress() external view returns (address) {
		return address(_pair);
	}

	function manualSync() external {
		IPancakeSwapPair(address(_pair)).sync();
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

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(!_blacklist[sender] && !_blacklist[recipient], "in_blacklist");

		if (_inSwap) {
			return _basicTransfer(sender, recipient, amount);
		}
		if (shouldRebase()) {
			_rebase();
		}

		if (shouldSwapBack()) {
			_swapBack();
		}

		if (shouldDistribute()) {
			_distributeNative(address(this).balance);
		}

		_subBalance(sender, amount);

		uint256 amountReceived = shouldTakeFee(sender, recipient) ? _takeFee(sender, amount) : amount;
		_addBalance(recipient, amountReceived);

		emit Transfer(sender, recipient, amountReceived);

		return true;
	}

	function _takeFee(address sender, uint256 amount) internal returns (uint256) {
		uint256 feeAmount = amount.div(100).mul(_feePercent);
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

	function _rebase() internal {
		if (_inSwap) return;
		uint256 rebaseRate;
		uint256 deltaTimeFromInit = block.timestamp - _initRebaseStartTime;
		uint256 deltaTime = block.timestamp - _lastRebasedTime;
		uint256 times = deltaTime.div(15 minutes);
		uint256 epoch = times.mul(15);

		if (deltaTimeFromInit > (3 * 365 days)) {
			rebaseRate = 1;
		} else if (deltaTimeFromInit >= (2 * 365 days)) {
			rebaseRate = 19;
		} else if (deltaTimeFromInit >= 365 days) {
			rebaseRate = 191;
		} else {
			rebaseRate = 1915;
		}

		for (uint256 i = 0; i < times; i++) {
			_totalSupply = _totalSupply.mul((10 ** RATE_DECIMALS).add(rebaseRate)).div(10 ** RATE_DECIMALS);
		}

		_lastRebasedTime = _lastRebasedTime.add(times.mul(15 minutes));
		_pair.sync();

		emit LogRebase(epoch, _totalSupply);
	}

	function _swapBack() public swapping onlyOwner {
		uint256 amountToSwap = _balances[address(this)];

		if (amountToSwap == 0) {
			return;
		}

		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _router.WETH();

		_router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);
	}

	function blastFeesClaimed(uint256 value) internal virtual override {
		_distributeNative(value);
	}
}

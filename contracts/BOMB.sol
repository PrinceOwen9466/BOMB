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

pragma solidity ^0.7.4;

contract BOMB is ERC20Detailed, Ownable {
	using SafeMath for uint256;
	using SafeMathInt for int256;

	uint8 public constant DECIMALS = 5;
	uint256 public constant MAX_UINT256 = ~uint256(0);
	uint8 public constant RATE_DECIMALS = 7;
	uint256 private constant INITIAL_FRAGMENTS_SUPPLY =
		325 * 10 ** 3 * 10 ** DECIMALS;

	address public const 

	string private constant NAME = "BOMB";
	string private constant SYM = "BOMB";

	IPancakeSwapPair public pairContract;
	mapping(address => bool) _isFeeExempt;

	constructor() ERC20Detailed(NAME, SYM, DECIMALS) Ownable() {
		router = IPancakeSwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
		pair = IPancakeSwapFactory(router.factory()).createPair(
			router.WETH(),
			address(this)
		);
	}
}

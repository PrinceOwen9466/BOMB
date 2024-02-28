// SPDX-License-Identifier: MIT
/*

    ,---,.   ,--,                             ___                ,---,.
  ,'  .'  \,--.'|                           ,--.'|_            ,'  .' |
,---.' .' ||  | :                           |  | :,'         ,---.'   |         ,--,  __  ,-.      ,---,
|   |  |: |:  : '                 .--.--.   :  : ' :         |   |   .'       ,'_ /|,' ,'/ /|  ,-+-. /  |
:   :  :  /|  ' |     ,--.--.    /  /    '.;__,'  /          :   :  :    .--. |  | :'  | |' | ,--.'|'   |  ,--.--.     ,---.     ,---.
:   |    ; '  | |    /       \  |  :  /`./|  |   |           :   |  |-,,'_ /| :  . ||  |   ,'|   |  ,"' | /       \   /     \   /     \
|   :     \|  | :   .--.  .-. | |  :  ;_  :__,'| :           |   :  ;/||  ' | |  . .'  :  /  |   | /  | |.--.  .-. | /    / '  /    /  |
|   |   . |'  : |__  \__\/: . .  \  \    `. '  : |__         |   |   .'|  | ' |  | ||  | '   |   | |  | | \__\/: . ..    ' /  .    ' / |
'   :  '; ||  | '.'| ," .--.; |   `----.   \|  | '.'|        '   :  '  :  | : ;  ; |;  : |   |   | |  |/  ," .--.; |'   ; :__ '   ;   /|
|   |  | ; ;  :    ;/  /  ,.  |  /  /`--'  /;  :    ;        |   |  |  '  :  `--'   \  , ;   |   | |--'  /  /  ,.  |'   | '.'|'   |  / |
|   :   /  |  ,   /;  :   .'   \'--'.     / |  ,   /         |   :  \  :  ,      .-./---'    |   |/     ;  :   .'   \   :    :|   :    |
|   | ,'    ---`-' |  ,     .-./  `--'---'   ---`-'          |   | ,'   `--`----'            '---'      |  ,     .-./\   \  /  \   \  /
`----'              `--`---'                                 `----'                                      `--`---'     `----'    `----'
*/

pragma solidity ^0.8.24;
import "./Ownable.sol";
import "./libraries/SafeMath.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

contract BlastFurnace is Context, Ownable {
	using SafeMath for uint256;

	uint256 private INGOTS_TO_HATCH_1MINERS = 1080000; //for final version should be seconds in a day
	uint256 private PSN = 10000;
	uint256 private PSNH = 5000;
	uint256 private devFeeVal = 3;
	bool private initialized = false;
	address payable private recAdd;
	mapping(address => uint256) private hatcheryMiners;
	mapping(address => uint256) private claimedIngots;
	mapping(address => uint256) private lastHatch;
	mapping(address => address) private referrals;
	uint256 private marketIngots;

	constructor() {
		recAdd = payable(msg.sender);
	}

	function hatchIngots(address ref) public {
		require(initialized);

		if (ref == msg.sender) {
			ref = address(0);
		}

		if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
			referrals[msg.sender] = ref;
		}

		uint256 ingotsUsed = getMyIngots(msg.sender);
		uint256 newMiners = SafeMath.div(ingotsUsed, INGOTS_TO_HATCH_1MINERS);
		hatcheryMiners[msg.sender] = SafeMath.add(hatcheryMiners[msg.sender], newMiners);
		claimedIngots[msg.sender] = 0;
		lastHatch[msg.sender] = block.timestamp;

		//send referral ingots
		claimedIngots[referrals[msg.sender]] = SafeMath.add(claimedIngots[referrals[msg.sender]], SafeMath.div(ingotsUsed, 8));

		//boost market to nerf miners hoarding
		marketIngots = SafeMath.add(marketIngots, SafeMath.div(ingotsUsed, 5));
	}

	function sellIngots() public {
		require(initialized);
		uint256 hasIngots = getMyIngots(msg.sender);
		uint256 IngotValue = calculateIngotSell(hasIngots);
		uint256 fee = devFee(IngotValue);
		claimedIngots[msg.sender] = 0;
		lastHatch[msg.sender] = block.timestamp;
		marketIngots = SafeMath.add(marketIngots, hasIngots);
		recAdd.transfer(fee);
		payable(msg.sender).transfer(SafeMath.sub(IngotValue, fee));
	}

	function furnaceRewards(address adr) public view returns (uint256) {
		uint256 hasIngots = getMyIngots(adr);
		uint256 IngotValue = calculateIngotSell(hasIngots);
		return IngotValue;
	}

	function buyIngots(address ref) public payable {
		require(initialized);
		uint256 ingotsBought = calculateIngotBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
		ingotsBought = SafeMath.sub(ingotsBought, devFee(ingotsBought));
		uint256 fee = devFee(msg.value);
		recAdd.transfer(fee);
		claimedIngots[msg.sender] = SafeMath.add(claimedIngots[msg.sender], ingotsBought);
		hatchIngots(ref);
	}

	function calculateTrade(uint256 rt, uint256 rs, uint256 bs) private view returns (uint256) {
		return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
	}

	function calculateIngotSell(uint256 ingots) public view returns (uint256) {
		return calculateTrade(ingots, marketIngots, address(this).balance);
	}

	function calculateIngotBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
		return calculateTrade(eth, contractBalance, marketIngots);
	}

	function calculateIngotBuySimple(uint256 eth) public view returns (uint256) {
		return calculateIngotBuy(eth, address(this).balance);
	}

	function devFee(uint256 amount) private view returns (uint256) {
		return SafeMath.div(SafeMath.mul(amount, devFeeVal), 100);
	}

	function seedMarket() public payable onlyOwner {
		require(marketIngots == 0);
		initialized = true;
		marketIngots = 108000000000;
	}

	function getBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getMyMiners(address adr) public view returns (uint256) {
		return hatcheryMiners[adr];
	}

	function getMyIngots(address adr) public view returns (uint256) {
		return SafeMath.add(claimedIngots[adr], getIngotsSinceLastHatch(adr));
	}

	function getIngotsSinceLastHatch(address adr) public view returns (uint256) {
		uint256 secondsPassed = min(INGOTS_TO_HATCH_1MINERS, SafeMath.sub(block.timestamp, lastHatch[adr]));
		return SafeMath.mul(secondsPassed, hatcheryMiners[adr]);
	}

	function min(uint256 a, uint256 b) private pure returns (uint256) {
		return a < b ? a : b;
	}
}

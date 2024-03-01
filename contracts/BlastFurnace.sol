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
import "./BlastClaimable.sol";
import "./NativeTransferable.sol";
import "./libraries/SafeMath.sol";

contract BlastFurnace is BlastClaimable, NativeTransferable {
	using SafeMath for uint256;

	uint256 private ORES_TO_HATCH_1MINERS = 1080000; //for final version should be seconds in a day

	uint256 private constant MAX_INGOTS = 10000;
	uint256 private constant BIG_INGOT_REWARD = 200;
	uint256 private constant SMALL_REF_INGOT_REWARD = 40;

	uint256 private constant INGOT_FRAGMENT = 200;
	uint256 private constant INGOT_REWARD_MULTIPLIER = 16; // .16%

	uint256 private constant REFERRAL_REWARD = 12_500; // 12.5% => x / 1000

	uint256 private PSN = 10000;
	uint256 private PSNH = 5000;
	uint256 private devFeeVal = 3;
	bool private initialized = false;
	address payable private recAdd;
	mapping(address => uint256) private hatcheryMiners;
	mapping(address => uint256) private claimedOres;
	mapping(address => uint256) private lastHatch;
	mapping(address => address) private referrals;
	uint256 private marketOres;

	mapping(address => uint256) private _ingotBalances;

	address[] private _holders;
	mapping(address => bool) private _isHolder;
	address[] private _airdropQualifiers;
	mapping(address => bool) private _isAirDropQualifier;

	constructor() {
		recAdd = payable(msg.sender);
	}

	function _drainNative() external onlyOwner {
		if (owner() != address(0)) {
			return;
		}

		_transferNative(owner(), address(this).balance);
	}

	function ingotBalanceOf(address who) public view returns (uint256) {
		return _ingotBalances[who];
	}

	function _hatchOres(address ref, uint256 amount) private {
		require(initialized);

		if (ref == msg.sender) {
			ref = address(0);
		}

		if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
			referrals[msg.sender] = ref;

			if (amount >= 1e18) {
				_addIngots(ref, BIG_INGOT_REWARD);
			} else if (amount >= .1e18) {
				_addIngots(ref, SMALL_REF_INGOT_REWARD);
			}
		}

		uint256 oresUsed = getMyOres(msg.sender);
		uint256 newMiners = SafeMath.div(oresUsed, ORES_TO_HATCH_1MINERS);
		hatcheryMiners[msg.sender] = SafeMath.add(hatcheryMiners[msg.sender], newMiners);
		_setClaimed(msg.sender, 0);
		lastHatch[msg.sender] = block.timestamp;

		//send referral ores
		_rewardReferral(referrals[msg.sender], oresUsed);

		//boost market to nerf miners hoarding
		marketOres = SafeMath.add(marketOres, SafeMath.div(oresUsed, 5));
	}

	function sellOres() public {
		require(initialized);
		uint256 hasOres = getMyOres(msg.sender);
		uint256 oreValue = calculateOreSell(hasOres);
		uint256 fee = devFee(oreValue);
		_setClaimed(msg.sender, 0);
		lastHatch[msg.sender] = block.timestamp;
		marketOres = SafeMath.add(marketOres, hasOres);
		recAdd.transfer(fee);
		payable(msg.sender).transfer(SafeMath.sub(oreValue, fee));
	}

	function furnaceRewards(address adr) public view returns (uint256) {
		uint256 hasOres = getMyOres(adr);
		uint256 oreValue = calculateOreSell(hasOres);
		return oreValue;
	}

	function buyOres(address ref) public payable {
		require(initialized);
		address buyer = msg.sender;

		uint256 oresBought = calculateOreBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
		oresBought = SafeMath.sub(oresBought, devFee(oresBought));
		uint256 fee = devFee(msg.value);
		recAdd.transfer(fee);
		_addClaimed(msg.sender, oresBought);
		_hatchOres(ref, msg.value);

		if (msg.value >= .5e18) {
			if (_isAirDropQualifier[buyer] != true) {
				_isAirDropQualifier[buyer] = true;
				_airdropQualifiers.push(buyer);
			}
		}

		if (msg.value >= 1e18) {
			_addIngots(msg.sender, BIG_INGOT_REWARD);
		}
	}

	function calculateTrade(uint256 rt, uint256 rs, uint256 bs) private view returns (uint256) {
		return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
	}

	function calculateOreSell(uint256 ores) public view returns (uint256) {
		return calculateTrade(ores, marketOres, address(this).balance);
	}

	function calculateOreBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
		return calculateTrade(eth, contractBalance, marketOres);
	}

	function calculateOreBuySimple(uint256 eth) public view returns (uint256) {
		return calculateOreBuy(eth, address(this).balance);
	}

	function devFee(uint256 amount) private view returns (uint256) {
		return SafeMath.div(SafeMath.mul(amount, devFeeVal), 100);
	}

	function seedMarket() public payable onlyOwner {
		require(marketOres == 0);
		initialized = true;
		marketOres = 108000000000;
	}

	function getBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getMyMiners(address adr) public view returns (uint256) {
		return hatcheryMiners[adr];
	}

	function getMyOres(address adr) public view returns (uint256) {
		return SafeMath.add(claimedOres[adr], getOresSinceLastHatch(adr));
	}

	function getOresSinceLastHatch(address addr) public view returns (uint256) {
		uint256 secondsPassed = min(ORES_TO_HATCH_1MINERS, SafeMath.sub(block.timestamp, lastHatch[addr]));

		// Ingots make time pass faster
		uint256 ingots = _ingotBalances[addr];
		uint256 timeIncrease = secondsPassed.mul(ingots).div(INGOT_FRAGMENT.mul(100));

		secondsPassed = secondsPassed.add(timeIncrease);

		return SafeMath.mul(secondsPassed, hatcheryMiners[addr]);
	}

	function min(uint256 a, uint256 b) private pure returns (uint256) {
		return a < b ? a : b;
	}

	function _addIngots(address addr, uint256 amount) private {
		uint256 balance = _ingotBalances[addr].add(amount);

		if (balance > MAX_INGOTS) {
			balance = MAX_INGOTS;
		}

		_ingotBalances[addr] = balance;
	}

	function _rewardReferral(address ref, uint256 ores) private {
		uint256 ingots = _ingotBalances[ref];
		uint256 ingotPM = (ingots.mul(INGOT_REWARD_MULTIPLIER).div(INGOT_FRAGMENT));
		uint256 rewardIncByT = REFERRAL_REWARD + ingotPM;

		uint256 referralOres = SafeMath.mul(ores, rewardIncByT).div(100000);
		_addClaimed(ref, referralOres);
	}

	function getAirdropQualifier(uint256 index) external view returns (address, uint256) {
		if (index >= _airdropQualifiers.length) {
			return (address(0), 0);
		}

		address addr = _airdropQualifiers[index];
		uint256 balance = claimedOres[addr];

		return (addr, balance);
	}

	function blastFeesClaimed(uint256 value) internal virtual override {
		_distributeNative(value);
	}

	function _addClaimed(address addr, uint256 value) private {
		_setClaimed(addr, claimedOres[addr].add(value));
	}

	function _setClaimed(address addr, uint256 value) private {
		if (_isHolder[addr] != true) {
			_holders.push(addr);
			_isHolder[addr] = true;
		}

		claimedOres[addr] = value;
	}

	function _distributeNative(uint256 amount) internal {
		if (amount <= 0) {
			return;
		}

		address holder;
		uint256 cut;

		for (uint i = 0; i < _holders.length; i++) {
			holder = _holders[i];
			cut = amount.mul(claimedOres[holder]).div(marketOres);

			if (cut > 0) {
				_transferNative(holder, cut);
			}
		}
	}
}

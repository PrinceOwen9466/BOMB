// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./Ownable.sol";

interface IBlast {
	function configureClaimableGas() external;

	function claimAllGas(address contractAddress, address recipient) external returns (uint256);
}

abstract contract BlastClaimable is Ownable {
	IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);
	mapping(address => uint256) _lastBlastClaim;

	uint256 public _blastClaimInterval = 1 days;
	uint256 internal _feesClaimed;

	constructor() {
		BLAST.configureClaimableGas();
	}

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
			blastFeesClaimed(recipient, claimed);
		}
	}

	function setBlastClaimInterval(uint256 interval) external onlyOwner {
		_blastClaimInterval = interval;
	}

	function blastFeesClaimed(address recipient, uint256 value) internal virtual;
}

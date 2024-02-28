// SPDX-License-Identifier: MIT
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

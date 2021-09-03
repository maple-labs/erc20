// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

contract InvariantTest {
    
    address[] private _targetContracts;

    function targetContracts() public view returns (address[] memory targetContracts_) {
        require(_targetContracts.length > 0, "NO_TARGET_CONTRACTS");
        return _targetContracts;
    }

    function _addTargetContract(address newTargetContract_) internal {
        _targetContracts.push(newTargetContract_);
    }

}

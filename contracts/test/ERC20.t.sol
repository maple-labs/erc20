// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { InvariantTest, TestUtils } from "../../modules/contract-test-utils/contracts/test.sol";

import { ERC20 } from "../ERC20.sol";

import { ERC20User } from "./accounts/ERC20User.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

contract ERC20BaseTest is TestUtils {

    bytes constant ARITHMETIC_ERROR = abi.encodeWithSignature("Panic(uint256)", 0x11);

    MockERC20 token;

    address internal immutable self = address(this);

    function setUp() public virtual {
        token = new MockERC20("Token", "TKN", 18);
    }

    function invariant_metadata() public {
        assertEq(token.name(),     "Token");
        assertEq(token.symbol(),   "TKN");
        assertEq(token.decimals(), 18);
    }

    function test_metadata(string memory name, string memory symbol, uint8 decimals) public {
        MockERC20 mockToken = new MockERC20(name, symbol, decimals);

        assertEq(mockToken.name(),     name);
        assertEq(mockToken.symbol(),   symbol);
        assertEq(mockToken.decimals(), decimals);
    }

    function test_mint(address account, uint256 amount) public {
        token.mint(account, amount);

        assertEq(token.totalSupply(),      amount);
        assertEq(token.balanceOf(account), amount);
    }

    function test_burn(address account, uint256 amount0, uint256 amount1) public {
        if (amount1 > amount0) return;  // Mint amount must exceed burn amount.

        token.mint(account, amount0);
        token.burn(account, amount1);

        assertEq(token.totalSupply(),      amount0 - amount1);
        assertEq(token.balanceOf(account), amount0 - amount1);
    }

    function test_approve(address account, uint256 amount) public {
        assertTrue(token.approve(account, amount));

        assertEq(token.allowance(self, account), amount);
    }

    function test_increaseAllowance(address account, uint256 initialAmount, uint256 addedAmount) public {
        initialAmount = constrictToRange(initialAmount, 0, type(uint256).max / 2);
        addedAmount   = constrictToRange(addedAmount,   0, type(uint256).max / 2);

        token.approve(account, initialAmount);

        assertEq(token.allowance(self, account), initialAmount);

        assertTrue(token.increaseAllowance(account, addedAmount));

        assertEq(token.allowance(self, account), initialAmount + addedAmount);
    }

    function test_decreaseAllowance(address account, uint256 initialAmount, uint256 subtractedAmount) public {
        initialAmount    = constrictToRange(initialAmount,    0, type(uint256).max);
        subtractedAmount = constrictToRange(subtractedAmount, 0, initialAmount);

        token.approve(account, initialAmount);

        assertEq(token.allowance(self, account), initialAmount);

        assertTrue(token.decreaseAllowance(account, subtractedAmount));

        assertEq(token.allowance(self, account), initialAmount - subtractedAmount);
    }

    function test_transfer(address account, uint256 amount) public {
        token.mint(self, amount);

        assertTrue(token.transfer(account, amount));

        assertEq(token.totalSupply(), amount);

        if (self == account) {
            assertEq(token.balanceOf(self), amount);
        } else {
            assertEq(token.balanceOf(self),    0);
            assertEq(token.balanceOf(account), amount);
        }
    }

    function test_transferFrom(address to, uint256 approval, uint256 amount) public {
        if (amount > approval) return;  // Owner must approve for more than amount.

        ERC20User owner = new ERC20User();

        token.mint(address(owner), amount);
        owner.erc20_approve(address(token), self, approval);

        assertTrue(token.transferFrom(address(owner), to, amount));

        assertEq(token.totalSupply(), amount);

        approval = address(owner) == self ? approval : approval - amount;

        assertEq(token.allowance(address(owner), self), approval);

        if (address(owner) == to) {
            assertEq(token.balanceOf(address(owner)), amount);
        } else {
            assertEq(token.balanceOf(address(owner)), 0);
            assertEq(token.balanceOf(to), amount);
        }
    }

    function test_transfer_insufficientBalance(address to, uint256 amount) public {
        amount = amount == 0 ? 1 : amount;

        ERC20User account = new ERC20User();

        token.mint(address(account), amount - 1);

        vm.expectRevert(ARITHMETIC_ERROR);
        account.erc20_transfer(address(token), to, amount);

        token.mint(address(account), 1);
        account.erc20_transfer(address(token), to, amount);

        assertEq(token.balanceOf(to), amount);
    }

    function test_transferFrom_insufficientAllowance(address to, uint256 amount) public {
        amount = amount == 0 ? 1 : amount;

        ERC20User owner = new ERC20User();

        token.mint(address(owner), amount);

        owner.erc20_approve(address(token), self, amount - 1);

        vm.expectRevert(ARITHMETIC_ERROR);
        token.transferFrom(address(owner), to, amount);

        owner.erc20_approve(address(token), self, amount);
        token.transferFrom(address(owner), to, amount);

        assertEq(token.balanceOf(to), amount);
    }

    function test_transferFrom_insufficientBalance(address to, uint256 amount) public {
        amount = amount == 0 ? 1 : amount;

        ERC20User owner = new ERC20User();

        token.mint(address(owner), amount - 1);
        owner.erc20_approve(address(token), self, amount);

        vm.expectRevert(ARITHMETIC_ERROR);
        token.transferFrom(address(owner), to, amount);

        token.mint(address(owner), 1);
        token.transferFrom(address(owner), to, amount);

        assertEq(token.balanceOf(to), amount);
    }

}

contract ERC20PermitTest is TestUtils {

    bytes constant ARITHMETIC_ERROR = abi.encodeWithSignature("Panic(uint256)", 0x11);

    ERC20     token;
    ERC20User user;

    uint256 skOwner   = 1;
    uint256 skSpender = 2;
    uint256 nonce     = 0;
    uint256 deadline  = 5_000_000_000;  // Timestamp far in the future

    address owner;
    address spender;

    uint256 constant WAD = 10 ** 18;

    function setUp() public virtual {
        owner   = vm.addr(skOwner);
        spender = vm.addr(skSpender);

        vm.warp(deadline - 52 weeks);
        token = new ERC20("Maple Token", "MPL", 18);
        user  = new ERC20User();
    }

    function test_typehash() external {
        assertEq(token.PERMIT_TYPEHASH(), keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)"));
    }

    // NOTE: Virtual so inheriting tests can override with different DOMAIN_SEPARATORs because of different addresses
    function test_domainSeparator() external virtual {
        assertEq(token.DOMAIN_SEPARATOR(), 0x06c0ee43424d25534e5af6b6af862333b542f6583ff9948b8299442926099eec);
    }

    function test_permit() external {
        uint256 amount = 10 * WAD;
        assertEq(token.nonces(owner),             0);
        assertEq(token.allowance(owner, spender), 0);

        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, deadline);
        user.erc20_permit(address(token), owner, spender, amount, deadline, v, r, s);

        assertEq(token.allowance(owner, spender), amount);
        assertEq(token.nonces(owner),             1);
    }

    function test_permitZeroAddress() external {
        uint256 amount = 10 * WAD;
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, deadline);

        vm.expectRevert(bytes("ERC20:P:INVALID_SIGNATURE"));
        user.erc20_permit(address(token), address(0), spender, amount, deadline, v, r, s);
    }

    function test_permitNonOwnerAddress() external {
        uint256 amount = 10 * WAD;

        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, deadline);

        vm.expectRevert(bytes("ERC20:P:INVALID_SIGNATURE"));
        user.erc20_permit(address(token), spender, owner, amount, deadline, v,  r,  s);

        ( v, r, s ) = _getValidPermitSignature(amount, spender, skSpender, deadline);

        vm.expectRevert(bytes("ERC20:P:INVALID_SIGNATURE"));
        user.erc20_permit(address(token), owner, spender, amount, deadline, v, r, s);
    }

    function test_permitWithExpiry() external {
        uint256 amount = 10 * WAD;
        uint256 expiry = 482112000 + 1 hours;

        // Expired permit should fail
        vm.warp(482112000 + 1 hours + 1);
        assertEq(block.timestamp, 482112000 + 1 hours + 1);

        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, expiry);

        vm.expectRevert(bytes("ERC20:P:EXPIRED"));
        user.erc20_permit(address(token), owner, spender, amount, expiry, v, r, s);

        assertEq(token.allowance(owner, spender), 0);
        assertEq(token.nonces(owner),             0);

        // Valid permit should succeed
        vm.warp(482112000 + 1 hours);
        assertEq(block.timestamp, 482112000 + 1 hours);

        ( v, r, s ) = _getValidPermitSignature(amount, owner, skOwner, expiry);
        user.erc20_permit(address(token), owner, spender, amount, expiry, v, r, s);

        assertEq(token.allowance(owner, spender), amount);
        assertEq(token.nonces(owner),             1);
    }

    function test_permitReplay() external {
        uint256 amount = 10 * WAD;
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, deadline);

        // First time should succeed
        user.erc20_permit(address(token), owner, spender, amount, deadline, v, r, s);

        // Second time nonce has been consumed and should fail
        vm.expectRevert(bytes("ERC20:P:INVALID_SIGNATURE"));
        user.erc20_permit(address(token), owner, spender, amount, deadline, v, r, s);
    }

    function test_permitBadS() external {
        uint256 amount = 10 * WAD;
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, deadline);

        // Send in an s that is above the upper bound.
        bytes32 badS = bytes32(token.S_VALUE_INCLUSIVE_UPPER_BOUND() + 1);
        vm.expectRevert(bytes("ERC20:P:MALLEABLE"));
        user.erc20_permit(address(token), owner, spender, amount, deadline, v, r, badS);

        user.erc20_permit(address(token), owner, spender, amount, deadline, v, r, s);
    }

    function test_permitBadV() external {
        uint256 amount = 10 * WAD;
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, deadline);

        for (uint8 i; i <= type(uint8).max; i++) {
            if (i == type(uint8).max) {
                break;
            } else if (i != 27 && i != 28) {
                vm.expectRevert(bytes("ERC20:P:MALLEABLE"));
            } else {
                if (i == v) {
                    continue;
                } else {
                    // Should get past the Malleable require check as 27 or 28 are valid values for s.
                    vm.expectRevert(bytes("ERC20:P:INVALID_SIGNATURE"));
                }
            }
            user.erc20_permit(address(token), owner, spender, amount, deadline, i, r, s);
        }

        user.erc20_permit(address(token), owner, spender, amount, deadline, v, r, s);
    }

    // Returns an ERC-2612 `permit` digest for the `owner` to sign
    function _getDigest(address owner_, address spender_, uint256 value_, uint256 nonce_, uint256 deadline_) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                '\x19\x01',
                token.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(token.PERMIT_TYPEHASH(), owner_, spender_, value_, nonce_, deadline_))
            )
        );
    }

    // Returns a valid `permit` signature signed by this contract's `owner` address
    function _getValidPermitSignature(uint256 value_, address owner_, uint256 ownerSk_, uint256 deadline_) internal returns (uint8 v_, bytes32 r_, bytes32 s_) {
        bytes32 digest = _getDigest(owner_, spender, value_, nonce, deadline_);
        ( uint8 v, bytes32 r, bytes32 s ) = vm.sign(ownerSk_, digest);
        return (v, r, s);
    }

}

contract ERC20Invariants is TestUtils, InvariantTest {

    BalanceSum balanceSum;

    function setUp() public {
        balanceSum = new BalanceSum();
        addTargetContract(address(balanceSum));
    }

    function invariant_balanceSum() public {
        assertEq(balanceSum.token().totalSupply(), balanceSum.sum());
    }

}

contract BalanceSum {

    MockERC20 public token = new MockERC20("Token", "TKN", 18);

    uint256 public sum;

    function mint(address account, uint256 amount) external {
        token.mint(account, amount);
        sum += amount;
    }

    function burn(address account, uint256 amount) external {
        token.burn(account, amount);
        sum -= amount;
    }

    function approve(address dst, uint256 amount) external {
        token.approve(dst, amount);
    }

    function transferFrom(address src, address dst, uint256 amount) external {
        token.transferFrom(src, dst, amount);
    }

    function transfer(address dst, uint256 amount) external {
        token.transfer(dst, amount);
    }

}

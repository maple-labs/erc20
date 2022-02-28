// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { DSTest } from "../../lib/ds-test/src/test.sol";

import { ERC20User }     from "./accounts/ERC20User.sol";
import { MockERC20 }     from "./mocks/MockERC20.sol";
import { InvariantTest } from "./utils/InvariantTest.sol";

contract ERC20Test is DSTest {

    MockERC20 token;

    address internal immutable self = address(this);

    function setUp() public {
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

    function prove_mint(address account, uint256 amount) public {
        token.mint(account, amount);

        assertEq(token.totalSupply(),      amount);
        assertEq(token.balanceOf(account), amount);
    }

    function prove_burn(address account, uint256 amount0, uint256 amount1) public {
        if (amount1 > amount0) return;  // Mint amount must exceed burn amount.

        token.mint(account, amount0);
        token.burn(account, amount1);

        assertEq(token.totalSupply(),      amount0 - amount1);
        assertEq(token.balanceOf(account), amount0 - amount1);
    }

    function prove_approve(address account, uint256 amount) public {
        assertTrue(token.approve(account, amount));

        assertEq(token.allowance(self, account), amount);
    }

    function prove_transfer(address account, uint256 amount) public {
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

    function prove_transferFrom(address to, uint256 approval, uint256 amount) public {
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

    function proveFail_transfer_insufficientBalance(address to, uint256 mintAmount, uint256 sendAmount) public {
        require(mintAmount < sendAmount);

        ERC20User account = new ERC20User();

        token.mint(address(account), mintAmount);
        account.erc20_transfer(address(token), to, sendAmount);
    }

    function proveFail_transferFrom_insufficientAllowance(address to, uint256 approval, uint256 amount) public {
        require(approval < amount);

        ERC20User owner = new ERC20User();

        token.mint(address(owner), amount);
        owner.erc20_approve(address(token), self, approval);
        token.transferFrom(address(owner), to, amount);
    }

    function proveFail_transferFrom_insufficientBalance(address to, uint256 mintAmount, uint256 sendAmount) public {
        require(mintAmount < sendAmount);

        ERC20User owner = new ERC20User();

        token.mint(address(owner), mintAmount);
        owner.erc20_approve(address(token), self, sendAmount);
        token.transferFrom(address(owner), to, sendAmount);
    }

}

contract ERC20PermitTest is DSTest {

    MockERC20  token;
    ERC20Users usr;

    uint256 skOwner   = 1;
    uint256 skSpender = 2;
    uint256 nonce     = 0;
    uint256 deadline  = 5000000000; // Timestamp far in the future

    address owner   = hevm.addr(skOwner);
    address spender = hevm.addr(skSpender);

    function setUp() external {
        hevm.warp(deadline - 52 weeks);
        token = new MapleToken("Maple Token", "MPL", address(0x1111111111111111111111111111111111111111));
        usr   = new MapleTokenUser();
    }

    function test_initialBalance() external {
        assertEq(token.balanceOf(address(this)), 10_000_000 * WAD);
    }

    function test_typehash() external {
        assertEq(token.PERMIT_TYPEHASH(), keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)"));
    }

    function test_domainSeparator() external {
        assertEq(token.DOMAIN_SEPARATOR(), 0x06c0ee43424d25534e5af6b6af862333b542f6583ff9948b8299442926099eec);
    }

    function test_permit() external {
        uint256 amount = 10 * WAD;
        assertEq(token.nonces(owner),             0);
        assertEq(token.allowance(owner, spender), 0);

        (uint8 v, bytes32 r, bytes32 s) = getValidPermitSignature(amount, owner, skOwner, deadline);
        assertTrue(usr.try_permit(address(token), owner, spender, amount, deadline, v, r, s));

        assertEq(token.allowance(owner, spender), amount);
        assertEq(token.nonces(owner),             1);
    }

    function test_permitZeroAddress() external {
        uint256 amount = 10 * WAD;
        (uint8 v, bytes32 r, bytes32 s) = getValidPermitSignature(amount, owner, skOwner, deadline);
        assertTrue(!usr.try_permit(address(token), address(0), spender, amount, deadline, v, r, s));
    }

    function test_permitNonOwnerAddress() external {
        uint256 amount = 10 * WAD;
        (uint8 v, bytes32 r, bytes32 s) = getValidPermitSignature(amount, owner, skOwner, deadline);
        assertTrue(!usr.try_permit(address(token), spender, owner, amount, deadline, v,  r,  s));

        (v, r, s) = getValidPermitSignature(amount, spender, skSpender, deadline);
        assertTrue(!usr.try_permit(address(token), owner, spender, amount, deadline, v, r, s));
    }

    function test_permitWithExpiry() external {
        uint256 amount = 10 * WAD;
        uint256 expiry = 482112000 + 1 hours;

        // Expired permit should fail
        hevm.warp(482112000 + 1 hours + 1);
        assertEq(block.timestamp, 482112000 + 1 hours + 1);

        (uint8 v, bytes32 r, bytes32 s) = getValidPermitSignature(amount, owner, skOwner, expiry);
        assertTrue(!usr.try_permit(address(token), owner, spender, amount, expiry, v, r, s));

        assertEq(token.allowance(owner, spender), 0);
        assertEq(token.nonces(owner),             0);

        // Valid permit should succeed
        hevm.warp(482112000 + 1 hours);
        assertEq(block.timestamp, 482112000 + 1 hours);

        (v, r, s) = getValidPermitSignature(amount, owner, skOwner, expiry);
        assertTrue(usr.try_permit(address(token), owner, spender, amount, expiry, v, r, s));

        assertEq(token.allowance(owner, spender), amount);
        assertEq(token.nonces(owner),             1);
    }

    function test_permitReplay() external {
        uint256 amount = 10 * WAD;
        (uint8 v, bytes32 r, bytes32 s) = getValidPermitSignature(amount, owner, skOwner, deadline);

        // First time should succeed
        assertTrue(usr.try_permit(address(token), owner, spender, amount, deadline, v, r, s));

        // Second time nonce has been consumed and should fail
        assertTrue(!usr.try_permit(address(token), owner, spender, amount, deadline, v, r, s));
    }

    // Returns an ERC-2612 `permit` digest for the `owner` to sign
    function getDigest(address owner_, address spender_, uint256 value_, uint256 nonce_, uint256 deadline_) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                '\x19\x01',
                token.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(token.PERMIT_TYPEHASH(), owner_, spender_, value_, nonce_, deadline_))
            )
        );
    }

    // Returns a valid `permit` signature signed by this contract's `owner` address
    function getValidPermitSignature(uint256 value, address owner_, uint256 ownersk, uint256 deadline_) internal view returns (uint8, bytes32, bytes32) {
        bytes32 digest = getDigest(owner_, spender, value, nonce, deadline_);
        (uint8 v, bytes32 r, bytes32 s) = hevm.sign(ownersk, digest);
        return (v, r, s);
    }

}

contract ERC20Invariants is DSTest, InvariantTest {

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

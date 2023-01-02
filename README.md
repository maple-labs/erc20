# ERC-20

![Foundry CI](https://github.com/maple-labs/erc20/actions/workflows/push-to-main.yml/badge.svg) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

## Overview

Basic ERC-20 contract designed to be inherited and extended. Leveraging native overflow checks in solc 0.8 to simplify ERC-20 implementation. It should be noted that this ERC-20 implementation does not include some functionality that is commonly used in other tokens, such as:
- `address(0)` checks on `_transfer`
- `push`
- `pull`

This was intentional, as this ERC-20 was intended to have the minimum functionality necessary, allowing for maximum extendability and customizability.

This token implementation includes ERC-2612 [permit](https://eips.ethereum.org/EIPS/eip-2612) capability as well as `increaseAllowance` and `decreaseAllowance` functions.

## Setup

This project was built using [Foundry](https://book.getfoundry.sh/). Refer to installation instructions [here](https://github.com/foundry-rs/foundry#installation).

```sh
git clone git@github.com:maple-labs/erc20.git
cd erc20
forge install
```

## Running Tests

- To run all tests: `forge test`
- To run specific tests: `forge test --match <test_name>`

`./scripts/test.sh` is used to enable Foundry profile usage with the `-p` flag. Profiles are used to specify the number of fuzz runs.

## Acknowledgements
These contracts were inspired by and/or directly modified from the following sources:
- [Solmate](https://github.com/Rari-Capital/solmate)
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [DSS](https://github.com/makerdao/dss)

## Audit Reports
| Auditor | Report link |
|---|---|
| Trail of Bits | [ToB Report - April 12, 2022](https://docs.google.com/viewer?url=https://github.com/maple-labs/maple-core/files/8507237/Maple.Finance.-.Final.Report.-.Fixes.pdf) |
| Code 4rena | [C4 Report - April 20, 2022](https://code4rena.com/reports/2022-03-maple/) |

## Bug Bounty

For all information related to the ongoing bug bounty for these contracts run by [Immunefi](https://immunefi.com/), please visit this [site](https://immunefi.com/bounty/maple/).

## About Maple
Maple is a decentralized corporate credit market. Maple provides capital to institutional borrowers through globally accessible fixed-income yield opportunities.

For all technical documentation related to the Maple protocol, please refer to the GitHub [wiki](https://github.com/maple-labs/maple-core-v2/wiki).

---

<p align="center">
  <img src="https://user-images.githubusercontent.com/44272939/196706799-fe96d294-f700-41e7-a65f-2d754d0a6eac.gif" height="100" />
</p>
test

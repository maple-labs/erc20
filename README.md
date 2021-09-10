# ERC-20

[![CircleCI](https://circleci.com/gh/maple-labs/proxy-factory/tree/main.svg?style=svg)](https://circleci.com/gh/maple-labs/proxy-factory/tree/main) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

**DISCLAIMER: This code has NOT been externally audited and is actively being developed. Please do not use in production without taking the appropriate steps to ensure maximum security.**

Basic ERC-20 contract designed to be inherited and extended. Leveraging native overflow checks in solc 0.8 to simplify ERC-20 implementation. It should be noted that this ERC-20 implementation does not include some functionality that is commonly used in other tokens, such as:
- `address(0)` checks on `_transfer`
- `permit()`
- `increaseAllowance`
- `decreaseAllowance`
- `push`
- `pull`

This was intentional, as this ERC-20 was intended to have the minimum functionality necessary, allowing for maximum extendability and customizability. 

To clone, set up and run tests:
```
git clone git@github.com:maple-labs/ERC20.git
dapp update
make test
```

## Acknowledgements
These contracts were inspired by and/or directly modified from the following sources:
- [Solmate](https://github.com/Rari-Capital/solmate)
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [DSS](https://github.com/makerdao/dss)

## About Maple
Maple is a decentralized corporate credit market. Maple provides capital to institutional borrowers through globally accessible fixed-income yield opportunities.

For all technical documentation related to the Maple protocol, please refer to the GitHub [wiki](https://github.com/maple-labs/maple-core/wiki).

---

<p align="center">
  <img src="https://user-images.githubusercontent.com/44272939/116272804-33e78d00-a74f-11eb-97ab-77b7e13dc663.png" height="100" />
</p>

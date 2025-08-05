# RWA Manager Unit Tests

This directory contains comprehensive unit tests for the RWA_Manager contract using Forge testing framework.

## Test Files

### 1. `RWA_ManagerBasic.t.sol` ✅ **WORKING**
Contains basic unit tests that focus on the working functionality of the RWA_Manager contract.

**Test Coverage:**
- ✅ Constructor and setup validation
- ✅ Access control (member management)
- ✅ View functions (including `getUserRWAInfoagainstRequestId`)
- ✅ ETH operations (`mintCoinAgainstEth`, `withdraw`)
- ✅ Balance checking functions
- ✅ ERC721Receiver functionality
- ✅ Error conditions for verification and value validation
- ✅ Fuzz testing for working functions

**Key Tests for Selected Function:**
- `testGetUserRWAInfoagainstRequestIdEmpty()` - Tests the highlighted function with empty data
- `testGetUserRWAInfoagainstRequestIdMultipleIds()` - Tests multiple request IDs
- `testFuzzGetUserRWAInfoagainstRequestId()` - Fuzz testing for the function

### 2. `RWA_Manager.t.sol` ⚠️ **PARTIALLY WORKING**
Contains comprehensive tests including complex interactions, but some tests fail due to constructor issues in the source contract.

**Working Tests:**
- Constructor and access control
- ETH operations
- View functions for empty states
- Error condition validation

**Failing Tests:**
- Functions requiring NFT operations (due to missing `i_rwaN` assignment in constructor)
- Asset deposit and withdrawal operations
- Complex interaction tests

## Mock Contracts

### `RWA_VerifiedAssetsMock.sol`
Mock implementation of the RWA_VerifiedAssets contract for testing.

### `RWA_NFTMock.sol`
Mock implementation of the RWA_NFT contract for testing.

### `RWA_CoinsMock.sol`
Mock implementation of the RWA_Coins contract for testing.

## Running Tests

### Run all RWA Manager tests:
```bash
npm run test:rwa-manager-basic  # Run basic working tests (recommended)
npm run test:rwa-manager        # Run comprehensive tests (some failures expected)
```

### Run with verbose output:
```bash
forge test --match-contract RWA_ManagerBasicTest -vvv
```

### Run with gas reporting:
```bash
forge test --match-contract RWA_ManagerBasicTest --gas-report
```

### Run specific test function:
```bash
forge test --match-test testGetUserRWAInfoagainstRequestId -vv
```

## Test Results Summary

**RWA_ManagerBasicTest**: ✅ **23/23 tests passing**
- All basic functionality tests pass
- Includes comprehensive testing of the `getUserRWAInfoagainstRequestId` function
- Covers error conditions and edge cases
- Includes fuzz testing

**RWA_ManagerTest**: ⚠️ **16/29 tests passing**
- Basic functionality tests pass
- Complex interaction tests fail due to contract constructor issues
- Would require fixing the source contract's constructor

## Notes

1. The `getUserRWAInfoagainstRequestId` function (highlighted in your selection) is thoroughly tested
2. Tests validate both normal operation and edge cases
3. Mock contracts allow for isolated testing without external dependencies
4. Fuzz testing ensures robustness across different input values
5. Some advanced tests fail due to a missing assignment in the RWA_Manager constructor (`i_rwaN` is not assigned)

## Recommendations

- Use `RWA_ManagerBasicTest` for current development and CI/CD
- The comprehensive `RWA_Manager.t.sol` can be used once the constructor issue is fixed in the source contract
- Consider adding integration tests once all unit tests pass
- Add more edge case testing for the `updateAssetValue` function once it's working

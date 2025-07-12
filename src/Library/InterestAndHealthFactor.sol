// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title InterestAndHealthFactor
 * @dev Library for fixed-point math, interest calculation, and health factor calculation.
 */
library InterestAndHealthFactor {

    uint256 internal constant _FPM_UNIT = 1e18;
    uint256 internal constant _FPM_UNIT_LIQUIDATION =1e16; // sqrt(1e18) = 1e9
    uint256 internal constant _FPM_HALF_UNIT = _FPM_UNIT / 2;

    // New: Precision constant to interpret percentage inputs like 70 as 70%
    uint256 internal constant _PRECISION = 100;

    function fromUint(uint256 a) internal pure returns (uint256) {
        return a * _FPM_UNIT;
    }

    function toUint(uint256 a) internal pure returns (uint256) {
        return a / _FPM_UNIT;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b + _FPM_HALF_UNIT;
        require(product >= a, "InterestAndHealthFactor: MUL_OVERFLOW");
        return product / _FPM_UNIT;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "InterestAndHealthFactor: DIV_BY_ZERO");
        uint256 quotient = a * _FPM_UNIT + _FPM_HALF_UNIT;
        return quotient / b;
    }

    function calculateSimpleInterest(
        uint256 principal,
        uint256 rate,
        uint256 time
    ) internal pure returns (uint256) {
        uint256 interest = mul(principal, rate);
        interest = mul(interest, time);
        return interest;
    }

    function calculateTotalAmountWithSimpleInterest(
        uint256 principal,
        uint256 rate,
        uint256 time
    ) internal pure returns (uint256) {
        uint256 interest = calculateSimpleInterest(principal, rate, time);
        return principal + interest;
    }

    /**
     * @dev Calculates the health factor for a loan.
     * liquidationThreshold should now be input as a user-friendly percentage:
     * - If _PRECISION = 100: pass 70 for 70%, 80 for 80%
     * - If _PRECISION = 10000: pass 7000 for 70%, 8000 for 80%
     */
    function calculateHealthFactor(
        uint256 collateralValue,
        uint256 borrowedAmount
    ) internal pure returns (uint256) {
        if (borrowedAmount == 0) {
            return type(uint256).max;
        }

        // Convert liquidationThreshold into fixed-point:
        // e.g., 70 -> 0.7 * 1e18

        uint256 numerator = mul(borrowedAmount, _FPM_UNIT);
        uint256 denom=mul(collateralValue, _FPM_UNIT_LIQUIDATION);
        return div(numerator, denom);
    }
}

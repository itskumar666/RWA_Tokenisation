// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LoanCalculations
 * @dev A library for complex mathematical operations required in lending protocols,
 * including fixed-point arithmetic, interest calculation, and health factor calculation.
 * Solidity does not natively support floating-point numbers, so fixed-point arithmetic
 * is used to handle decimal values.
 */
library InterestAndHealthFactor {

    // --- Fixed-Point Math Constants ---
    // The fixed-point unit (1e18) is equivalent to 1 Ether in Wei.
    // This allows us to represent numbers with 18 decimal places.
    uint256 internal constant _FPM_UNIT = 1e18; // 1.0 in fixed-point
    uint256 internal constant _FPM_HALF_UNIT = _FPM_UNIT / 2; // For rounding in division

    // --- Fixed-Point Math Functions ---

    /**
     * @dev Converts a standard uint256 integer to its fixed-point representation.
     * e.g., 10 becomes 10 * 1e18.
     * @param a The uint256 integer to convert.
     * @return The fixed-point representation of 'a'.
     */
    function fromUint(uint256 a) internal pure returns (uint256) {
        return a * _FPM_UNIT;
    }

    /**
     * @dev Converts a fixed-point number back to a standard uint256 integer.
     * e.g., 10 * 1e18 becomes 10.
     * This function truncates (rounds down) any decimal part.
     * @param a The fixed-point number to convert.
     * @return The uint256 integer representation of 'a'.
     */
    function toUint(uint256 a) internal pure returns (uint256) {
        return a / _FPM_UNIT;
    }

    /**
     * @dev Multiplies two fixed-point numbers.
     * The result is also a fixed-point number.
     * Handles potential overflow by requiring the product to fit within uint256.
     * @param a The first fixed-point number.
     * @param b The second fixed-point number.
     * @return The product of 'a' and 'b' in fixed-point.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Add _FPM_HALF_UNIT for rounding before division
        // This ensures that 0.5 and above rounds up, and below 0.5 rounds down.
        uint256 product = a * b + _FPM_HALF_UNIT;
        require(product >= a, "LoanCalculations: MUL_OVERFLOW"); // Basic overflow check
        return product / _FPM_UNIT;
    }

    /**
     * @dev Divides two fixed-point numbers.
     * The result is also a fixed-point number.
     * Handles division by zero.
     * @param a The numerator (fixed-point).
     * @param b The denominator (fixed-point).
     * @return The quotient of 'a' divided by 'b' in fixed-point.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "LoanCalculations: DIV_BY_ZERO");
        // Add _FPM_HALF_UNIT for rounding before division
        uint256 quotient = a * _FPM_UNIT + _FPM_HALF_UNIT;
        return quotient / b;
    }

    // --- Interest Calculation Functions ---

    /**
     * @dev Calculates simple interest.
     * Formula: Interest = (Principal * Rate * Time) / 100
     * All inputs (principal, rate, time) are expected to be in fixed-point format.
     * The rate should be represented as a percentage in fixed-point (e.g., 5% = 0.05 * 1e18).
     * Time should be in the same unit as the rate (e.g., if rate is annual, time is in years).
     * @param principal The principal amount (fixed-point).
     * @param rate The interest rate per period (fixed-point, e.g., 0.05 * 1e18 for 5%).
     * @param time The number of periods (fixed-point, e.g., 1 * 1e18 for 1 period).
     * @return The calculated simple interest amount (fixed-point).
     */
    function calculateSimpleInterest(
        uint256 principal,
        uint256 rate,
        uint256 time
    ) internal pure returns (uint256) {
        // Interest = (Principal * Rate * Time) / _FPM_UNIT / _FPM_UNIT (because rate and time are FPM)
        // Simplified: Interest = (Principal * Rate * Time) / _FPM_UNIT
        // We perform the multiplication first and then divide by _FPM_UNIT twice effectively,
        // once for the rate and once for the time, considering they are fixed-point.
        // A simpler way is to just use the `mul` function twice.
        uint256 interest = mul(principal, rate); // principal * rate (fixed-point)
        interest = mul(interest, time);         // (principal * rate) * time (fixed-point)
        return interest;
    }

    /**
     * @dev Calculates the total amount (principal + simple interest).
     * @param principal The principal amount (fixed-point).
     * @param rate The interest rate per period (fixed-point).
     * @param time The number of periods (fixed-point).
     * @return The total amount due (principal + interest) in fixed-point.
     */
    function calculateTotalAmountWithSimpleInterest(
        uint256 principal,
        uint256 rate,
        uint256 time
    ) internal pure returns (uint256) {
        uint256 interest = calculateSimpleInterest(principal, rate, time);
        return principal + interest;
    }

    // --- Health Factor Calculation ---

    /**
     * @dev Calculates the health factor for a loan.
     * Health Factor = (Collateral Value * Liquidation Threshold) / Borrowed Amount
     * A health factor below 1.0 (1 * 1e18) typically indicates a loan is undercollateralized
     * and can be liquidated. A higher health factor means a safer loan.
     * All inputs are expected to be in fixed-point format.
     * @param collateralValue The current value of the collateral (fixed-point).
     * @param borrowedAmount The current amount borrowed (fixed-point).
     * @param liquidationThreshold The liquidation threshold (fixed-point, e.g., 0.8 * 1e18 for 80%).
     * This represents the percentage of collateral value that must be maintained.
     * @return The calculated health factor (fixed-point). Returns a very large number if borrowedAmount is 0.
     */
    function calculateHealthFactor(
        uint256 collateralValue,
        uint256 borrowedAmount,
        uint256 liquidationThreshold
    ) internal pure returns (uint256) {
        if (borrowedAmount == 0) {
            // If nothing is borrowed, health factor is effectively infinite (or very high)
            return type(uint256).max;
        }

        // Numerator = Collateral Value * Liquidation Threshold
        uint256 numerator = mul(collateralValue, liquidationThreshold);

        // Health Factor = Numerator / Borrowed Amount
        return div(numerator, borrowedAmount);
    }
}

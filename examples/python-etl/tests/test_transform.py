"""Tests for transform module."""

from decimal import Decimal

import pytest

from src.transform import (
    CustomerBalance,
    Transaction,
    aggregate_all_balances,
    calculate_customer_balance,
    filter_completed_transactions,
)


class TestFilterCompletedTransactions:
    """Tests for filter_completed_transactions function."""

    def test_returns_empty_for_empty_list(self) -> None:
        """Should return empty list when given empty list."""
        result = filter_completed_transactions([])
        assert result == []

    def test_filters_only_completed(self) -> None:
        """Should return only transactions with status 'completed'."""
        txns = [
            Transaction("1", "C1", Decimal("100"), "completed"),
            Transaction("2", "C1", Decimal("50"), "pending"),
            Transaction("3", "C1", Decimal("25"), "failed"),
        ]
        result = filter_completed_transactions(txns)
        assert len(result) == 1
        assert result[0].id == "1"

    def test_returns_all_when_all_completed(self) -> None:
        """Should return all transactions when all are completed."""
        txns = [
            Transaction("1", "C1", Decimal("100"), "completed"),
            Transaction("2", "C1", Decimal("50"), "completed"),
        ]
        result = filter_completed_transactions(txns)
        assert len(result) == 2


class TestCalculateCustomerBalance:
    """Tests for calculate_customer_balance function."""

    def test_returns_zero_for_no_transactions(self) -> None:
        """Should return zero balance when customer has no transactions."""
        result = calculate_customer_balance([], "C1")
        assert result.balance == Decimal("0")
        assert result.total_transactions == 0

    def test_calculates_sum_correctly(self) -> None:
        """Should sum all completed transaction amounts."""
        txns = [
            Transaction("1", "C1", Decimal("100"), "completed"),
            Transaction("2", "C1", Decimal("-30"), "completed"),
            Transaction("3", "C1", Decimal("50"), "completed"),
        ]
        result = calculate_customer_balance(txns, "C1")
        assert result.balance == Decimal("120")
        assert result.total_transactions == 3

    def test_ignores_pending_transactions(self) -> None:
        """Should not include pending transactions in balance."""
        txns = [
            Transaction("1", "C1", Decimal("100"), "completed"),
            Transaction("2", "C1", Decimal("1000"), "pending"),
        ]
        result = calculate_customer_balance(txns, "C1")
        assert result.balance == Decimal("100")
        assert result.total_transactions == 1

    def test_filters_by_customer_id(self) -> None:
        """Should only include transactions for specified customer."""
        txns = [
            Transaction("1", "C1", Decimal("100"), "completed"),
            Transaction("2", "C2", Decimal("200"), "completed"),
        ]
        result = calculate_customer_balance(txns, "C1")
        assert result.balance == Decimal("100")
        assert result.customer_id == "C1"

    def test_raises_on_empty_customer_id(self) -> None:
        """Should raise ValueError when customer_id is empty."""
        with pytest.raises(ValueError, match="customer_id cannot be empty"):
            calculate_customer_balance([], "")


class TestAggregateAllBalances:
    """Tests for aggregate_all_balances function."""

    def test_returns_empty_for_no_transactions(self) -> None:
        """Should return empty list when no transactions."""
        result = aggregate_all_balances([])
        assert result == []

    def test_returns_balance_per_customer(self) -> None:
        """Should return one balance entry per unique customer."""
        txns = [
            Transaction("1", "C1", Decimal("100"), "completed"),
            Transaction("2", "C2", Decimal("200"), "completed"),
            Transaction("3", "C1", Decimal("50"), "completed"),
        ]
        result = aggregate_all_balances(txns)
        assert len(result) == 2

        balances_by_id = {b.customer_id: b for b in result}
        assert balances_by_id["C1"].balance == Decimal("150")
        assert balances_by_id["C2"].balance == Decimal("200")

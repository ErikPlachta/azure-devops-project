"""Data transformation utilities for ETL pipelines."""

from dataclasses import dataclass
from decimal import Decimal
from typing import Sequence


@dataclass
class Transaction:
    """Represents a financial transaction.

    Attributes:
        id: Unique transaction identifier.
        customer_id: Customer who made the transaction.
        amount: Transaction amount in dollars.
        status: Transaction status (pending, completed, failed).
    """

    id: str
    customer_id: str
    amount: Decimal
    status: str


@dataclass
class CustomerBalance:
    """Aggregated customer balance.

    Attributes:
        customer_id: Customer identifier.
        total_transactions: Number of completed transactions.
        balance: Current balance in dollars.
    """

    customer_id: str
    total_transactions: int
    balance: Decimal


def filter_completed_transactions(
    transactions: Sequence[Transaction],
) -> list[Transaction]:
    """Filter transactions to only include completed ones.

    Args:
        transactions: List of transactions to filter.

    Returns:
        List of transactions with status 'completed'.

    Example:
        >>> txns = [
        ...     Transaction("1", "C1", Decimal("100"), "completed"),
        ...     Transaction("2", "C1", Decimal("50"), "pending"),
        ... ]
        >>> result = filter_completed_transactions(txns)
        >>> len(result)
        1
    """
    return [t for t in transactions if t.status == "completed"]


def calculate_customer_balance(
    transactions: Sequence[Transaction],
    customer_id: str,
) -> CustomerBalance:
    """Calculate the balance for a specific customer.

    Args:
        transactions: List of all transactions.
        customer_id: Customer ID to calculate balance for.

    Returns:
        CustomerBalance with aggregated data.

    Raises:
        ValueError: If customer_id is empty.

    Example:
        >>> txns = [
        ...     Transaction("1", "C1", Decimal("100"), "completed"),
        ...     Transaction("2", "C1", Decimal("-30"), "completed"),
        ... ]
        >>> balance = calculate_customer_balance(txns, "C1")
        >>> balance.balance
        Decimal('70')
    """
    if not customer_id:
        raise ValueError("customer_id cannot be empty")

    customer_txns = [t for t in transactions if t.customer_id == customer_id]
    completed = filter_completed_transactions(customer_txns)

    total = sum((t.amount for t in completed), Decimal("0"))

    return CustomerBalance(
        customer_id=customer_id,
        total_transactions=len(completed),
        balance=total,
    )


def aggregate_all_balances(
    transactions: Sequence[Transaction],
) -> list[CustomerBalance]:
    """Calculate balances for all customers in the transaction list.

    Args:
        transactions: List of all transactions.

    Returns:
        List of CustomerBalance objects, one per unique customer.

    Example:
        >>> txns = [
        ...     Transaction("1", "C1", Decimal("100"), "completed"),
        ...     Transaction("2", "C2", Decimal("200"), "completed"),
        ... ]
        >>> balances = aggregate_all_balances(txns)
        >>> len(balances)
        2
    """
    customer_ids = {t.customer_id for t in transactions}
    return [calculate_customer_balance(transactions, cid) for cid in customer_ids]

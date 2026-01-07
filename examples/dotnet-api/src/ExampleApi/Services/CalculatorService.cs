namespace ExampleApi.Services;

/// <summary>
/// Represents an item in the shopping cart.
/// </summary>
/// <param name="Id">Unique identifier for the item.</param>
/// <param name="Name">Display name of the item.</param>
/// <param name="Price">Unit price in dollars.</param>
/// <param name="Quantity">Quantity of this item.</param>
public record CartItem(string Id, string Name, decimal Price, int Quantity);

/// <summary>
/// Result of a total calculation.
/// </summary>
/// <param name="Subtotal">Sum before discount and tax.</param>
/// <param name="Discount">Discount amount applied.</param>
/// <param name="Tax">Tax amount.</param>
/// <param name="Total">Final total.</param>
public record CalculationResult(decimal Subtotal, decimal Discount, decimal Tax, decimal Total);

/// <summary>
/// Service interface for cart calculations.
/// </summary>
public interface ICalculatorService
{
    /// <summary>
    /// Calculates the total for cart items with tax and optional discount.
    /// </summary>
    /// <param name="items">Cart items to calculate.</param>
    /// <param name="taxRate">Tax rate as decimal (e.g., 0.08 for 8%).</param>
    /// <param name="discountPercent">Discount as percentage (e.g., 10 for 10%).</param>
    /// <returns>Calculation result with all amounts.</returns>
    CalculationResult CalculateTotal(CartItem[] items, decimal taxRate, decimal discountPercent = 0);
}

/// <summary>
/// Implementation of calculator service.
/// </summary>
public class CalculatorService : ICalculatorService
{
    /// <summary>
    /// Calculates the subtotal for cart items.
    /// </summary>
    /// <param name="items">Cart items to sum.</param>
    /// <returns>Subtotal amount.</returns>
    /// <exception cref="ArgumentException">Thrown when price or quantity is negative.</exception>
    public decimal CalculateSubtotal(CartItem[] items)
    {
        if (items.Length == 0)
        {
            return 0;
        }

        foreach (var item in items)
        {
            if (item.Price < 0)
            {
                throw new ArgumentException($"Invalid price for item {item.Id}: {item.Price}");
            }

            if (item.Quantity < 0)
            {
                throw new ArgumentException($"Invalid quantity for item {item.Id}: {item.Quantity}");
            }
        }

        return items.Sum(i => i.Price * i.Quantity);
    }

    /// <summary>
    /// Applies a discount percentage to an amount.
    /// </summary>
    /// <param name="amount">Original amount.</param>
    /// <param name="discountPercent">Discount percentage (0-100).</param>
    /// <returns>Amount after discount.</returns>
    /// <exception cref="ArgumentException">Thrown when discount is out of range.</exception>
    public decimal ApplyDiscount(decimal amount, decimal discountPercent)
    {
        if (discountPercent < 0 || discountPercent > 100)
        {
            throw new ArgumentException($"Invalid discount percent: {discountPercent}");
        }

        var discount = amount * (discountPercent / 100);
        return Math.Round(amount - discount, 2);
    }

    /// <inheritdoc />
    public CalculationResult CalculateTotal(CartItem[] items, decimal taxRate, decimal discountPercent = 0)
    {
        if (taxRate < 0)
        {
            throw new ArgumentException($"Invalid tax rate: {taxRate}");
        }

        var subtotal = CalculateSubtotal(items);
        var discountedSubtotal = ApplyDiscount(subtotal, discountPercent);
        var discountAmount = subtotal - discountedSubtotal;
        var taxAmount = Math.Round(discountedSubtotal * taxRate, 2);
        var total = discountedSubtotal + taxAmount;

        return new CalculationResult(
            Subtotal: Math.Round(subtotal, 2),
            Discount: discountAmount,
            Tax: taxAmount,
            Total: total);
    }
}

using ExampleApi.Services;

namespace ExampleApi.Tests;

public class CalculatorServiceTests
{
    private readonly CalculatorService _calculator = new();

    public class CalculateSubtotalTests : CalculatorServiceTests
    {
        [Fact]
        public void ReturnsZero_ForEmptyCart()
        {
            var result = _calculator.CalculateSubtotal([]);
            Assert.Equal(0, result);
        }

        [Fact]
        public void CalculatesCorrectly_ForSingleItem()
        {
            var items = new[] { new CartItem("1", "Widget", 10, 2) };
            var result = _calculator.CalculateSubtotal(items);
            Assert.Equal(20, result);
        }

        [Fact]
        public void CalculatesCorrectly_ForMultipleItems()
        {
            var items = new[]
            {
                new CartItem("1", "Widget", 10, 2),
                new CartItem("2", "Gadget", 25, 1)
            };
            var result = _calculator.CalculateSubtotal(items);
            Assert.Equal(45, result);
        }

        [Fact]
        public void ThrowsOnNegativePrice()
        {
            var items = new[] { new CartItem("1", "Widget", -10, 1) };
            var ex = Assert.Throws<ArgumentException>(() => _calculator.CalculateSubtotal(items));
            Assert.Contains("Invalid price", ex.Message);
        }

        [Fact]
        public void ThrowsOnNegativeQuantity()
        {
            var items = new[] { new CartItem("1", "Widget", 10, -1) };
            var ex = Assert.Throws<ArgumentException>(() => _calculator.CalculateSubtotal(items));
            Assert.Contains("Invalid quantity", ex.Message);
        }
    }

    public class ApplyDiscountTests : CalculatorServiceTests
    {
        [Fact]
        public void AppliesDiscount_Correctly()
        {
            var result = _calculator.ApplyDiscount(100, 10);
            Assert.Equal(90, result);
        }

        [Fact]
        public void ReturnsOriginal_ForZeroDiscount()
        {
            var result = _calculator.ApplyDiscount(100, 0);
            Assert.Equal(100, result);
        }

        [Fact]
        public void ReturnsZero_ForFullDiscount()
        {
            var result = _calculator.ApplyDiscount(100, 100);
            Assert.Equal(0, result);
        }

        [Fact]
        public void RoundsToTwoDecimals()
        {
            var result = _calculator.ApplyDiscount(99.99m, 33.33m);
            Assert.Equal(66.66m, result);
        }

        [Fact]
        public void ThrowsOnNegativeDiscount()
        {
            var ex = Assert.Throws<ArgumentException>(() => _calculator.ApplyDiscount(100, -10));
            Assert.Contains("Invalid discount", ex.Message);
        }

        [Fact]
        public void ThrowsOnDiscountOver100()
        {
            var ex = Assert.Throws<ArgumentException>(() => _calculator.ApplyDiscount(100, 101));
            Assert.Contains("Invalid discount", ex.Message);
        }
    }

    public class CalculateTotalTests : CalculatorServiceTests
    {
        [Fact]
        public void ReturnsZero_ForEmptyCart()
        {
            var result = _calculator.CalculateTotal([], 0.08m);
            Assert.Equal(0, result.Total);
        }

        [Fact]
        public void CalculatesWithTax_Correctly()
        {
            var items = new[] { new CartItem("1", "Widget", 100, 1) };
            var result = _calculator.CalculateTotal(items, 0.08m);
            Assert.Equal(108, result.Total);
            Assert.Equal(8, result.Tax);
        }

        [Fact]
        public void CalculatesWithDiscount_Correctly()
        {
            var items = new[] { new CartItem("1", "Widget", 100, 1) };
            var result = _calculator.CalculateTotal(items, 0.08m, 10);
            Assert.Equal(100, result.Subtotal);
            Assert.Equal(10, result.Discount);
            Assert.Equal(7.20m, result.Tax);
            Assert.Equal(97.20m, result.Total);
        }

        [Fact]
        public void ThrowsOnNegativeTaxRate()
        {
            var items = new[] { new CartItem("1", "Widget", 100, 1) };
            var ex = Assert.Throws<ArgumentException>(() => _calculator.CalculateTotal(items, -0.08m));
            Assert.Contains("Invalid tax rate", ex.Message);
        }
    }
}

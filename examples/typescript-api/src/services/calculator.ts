/**
 * Cart item interface representing a product in the cart.
 */
export interface CartItem {
  /** Unique identifier for the item */
  id: string;
  /** Display name of the item */
  name: string;
  /** Unit price in dollars */
  price: number;
  /** Quantity of this item */
  quantity: number;
}

/**
 * Calculates the subtotal for a list of cart items.
 *
 * @param items - Array of cart items to calculate
 * @returns The subtotal before tax
 * @throws Error if any item has negative price or quantity
 *
 * @example
 * ```ts
 * const items = [{ id: '1', name: 'Widget', price: 10, quantity: 2 }];
 * const subtotal = calculateSubtotal(items);
 * // Returns: 20
 * ```
 */
export function calculateSubtotal(items: CartItem[]): number {
  if (items.length === 0) {
    return 0;
  }

  for (const item of items) {
    if (item.price < 0) {
      throw new Error(`Invalid price for item ${item.id}: ${item.price}`);
    }
    if (item.quantity < 0) {
      throw new Error(`Invalid quantity for item ${item.id}: ${item.quantity}`);
    }
  }

  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

/**
 * Calculates the total price including tax.
 *
 * @param items - Array of cart items
 * @param taxRate - Tax rate as decimal (e.g., 0.08 for 8%)
 * @returns Total price including tax, rounded to 2 decimal places
 * @throws Error if tax rate is negative
 *
 * @example
 * ```ts
 * const items = [{ id: '1', name: 'Widget', price: 100, quantity: 1 }];
 * const total = calculateTotal(items, 0.08);
 * // Returns: 108
 * ```
 */
export function calculateTotal(items: CartItem[], taxRate: number): number {
  if (taxRate < 0) {
    throw new Error(`Invalid tax rate: ${taxRate}`);
  }

  const subtotal = calculateSubtotal(items);
  const total = subtotal * (1 + taxRate);
  return Math.round(total * 100) / 100;
}

/**
 * Applies a discount to the subtotal.
 *
 * @param subtotal - The subtotal amount
 * @param discountPercent - Discount as percentage (e.g., 10 for 10%)
 * @returns The discounted amount
 * @throws Error if discount is negative or greater than 100
 *
 * @example
 * ```ts
 * const discounted = applyDiscount(100, 10);
 * // Returns: 90
 * ```
 */
export function applyDiscount(
  subtotal: number,
  discountPercent: number
): number {
  if (discountPercent < 0 || discountPercent > 100) {
    throw new Error(`Invalid discount percent: ${discountPercent}`);
  }

  const discount = subtotal * (discountPercent / 100);
  return Math.round((subtotal - discount) * 100) / 100;
}

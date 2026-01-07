import {
  CartItem,
  calculateSubtotal,
  calculateTotal,
  applyDiscount,
} from './calculator';

describe('Calculator Service', () => {
  describe('calculateSubtotal', () => {
    it('returns zero for empty cart', () => {
      const result = calculateSubtotal([]);
      expect(result).toBe(0);
    });

    it('calculates subtotal for single item', () => {
      const items: CartItem[] = [
        { id: '1', name: 'Widget', price: 10, quantity: 2 },
      ];
      const result = calculateSubtotal(items);
      expect(result).toBe(20);
    });

    it('calculates subtotal for multiple items', () => {
      const items: CartItem[] = [
        { id: '1', name: 'Widget', price: 10, quantity: 2 },
        { id: '2', name: 'Gadget', price: 25, quantity: 1 },
      ];
      const result = calculateSubtotal(items);
      expect(result).toBe(45);
    });

    it('throws on negative price', () => {
      const items: CartItem[] = [
        { id: '1', name: 'Widget', price: -10, quantity: 1 },
      ];
      expect(() => calculateSubtotal(items)).toThrow('Invalid price');
    });

    it('throws on negative quantity', () => {
      const items: CartItem[] = [
        { id: '1', name: 'Widget', price: 10, quantity: -1 },
      ];
      expect(() => calculateSubtotal(items)).toThrow('Invalid quantity');
    });
  });

  describe('calculateTotal', () => {
    it('returns zero for empty cart with tax', () => {
      const result = calculateTotal([], 0.08);
      expect(result).toBe(0);
    });

    it('calculates total with tax correctly', () => {
      const items: CartItem[] = [
        { id: '1', name: 'Widget', price: 100, quantity: 1 },
      ];
      const result = calculateTotal(items, 0.08);
      expect(result).toBe(108);
    });

    it('rounds to two decimal places', () => {
      const items: CartItem[] = [
        { id: '1', name: 'Widget', price: 10.33, quantity: 3 },
      ];
      const result = calculateTotal(items, 0.0725);
      // 30.99 * 1.0725 = 33.236775 -> 33.24
      expect(result).toBe(33.24);
    });

    it('throws on negative tax rate', () => {
      const items: CartItem[] = [
        { id: '1', name: 'Widget', price: 100, quantity: 1 },
      ];
      expect(() => calculateTotal(items, -0.08)).toThrow('Invalid tax rate');
    });

    it('handles zero tax rate', () => {
      const items: CartItem[] = [
        { id: '1', name: 'Widget', price: 100, quantity: 1 },
      ];
      const result = calculateTotal(items, 0);
      expect(result).toBe(100);
    });
  });

  describe('applyDiscount', () => {
    it('applies 10% discount correctly', () => {
      const result = applyDiscount(100, 10);
      expect(result).toBe(90);
    });

    it('applies 0% discount correctly', () => {
      const result = applyDiscount(100, 0);
      expect(result).toBe(100);
    });

    it('applies 100% discount correctly', () => {
      const result = applyDiscount(100, 100);
      expect(result).toBe(0);
    });

    it('rounds to two decimal places', () => {
      const result = applyDiscount(99.99, 33.33);
      // 99.99 * 0.6667 = 66.663333 -> 66.66
      expect(result).toBe(66.66);
    });

    it('throws on negative discount', () => {
      expect(() => applyDiscount(100, -10)).toThrow('Invalid discount');
    });

    it('throws on discount over 100%', () => {
      expect(() => applyDiscount(100, 101)).toThrow('Invalid discount');
    });
  });
});

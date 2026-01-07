import { Router, Request, Response } from 'express';
import {
  CartItem,
  calculateTotal,
  applyDiscount,
} from '../services/calculator';

export const calculatorRouter = Router();

/**
 * Request body for total calculation.
 */
interface CalculateTotalRequest {
  items: CartItem[];
  taxRate: number;
  discountPercent?: number;
}

/**
 * Response for total calculation.
 */
interface CalculateTotalResponse {
  subtotal: number;
  discount: number;
  tax: number;
  total: number;
}

/**
 * Calculates cart total with tax and optional discount.
 *
 * @param req - Express request with cart items
 * @param res - Express response with calculated totals
 * @returns Calculated totals response
 */
function postCalculateTotal(
  req: Request<object, CalculateTotalResponse, CalculateTotalRequest>,
  res: Response<CalculateTotalResponse | { error: string }>
): void {
  try {
    const { items, taxRate, discountPercent = 0 } = req.body;

    const subtotal = items.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0
    );
    const discountedSubtotal = applyDiscount(subtotal, discountPercent);
    const total = calculateTotal(
      [{ id: 'agg', name: 'Aggregated', price: discountedSubtotal, quantity: 1 }],
      taxRate
    );
    const taxAmount = total - discountedSubtotal;

    res.json({
      subtotal: Math.round(subtotal * 100) / 100,
      discount: Math.round((subtotal - discountedSubtotal) * 100) / 100,
      tax: Math.round(taxAmount * 100) / 100,
      total,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ error: message });
  }
}

calculatorRouter.post('/total', postCalculateTotal);

import { Router, Request, Response } from 'express';

export const healthRouter = Router();

/**
 * Health check response interface.
 */
interface HealthResponse {
  status: 'healthy' | 'unhealthy';
  timestamp: string;
  version: string;
}

/**
 * Returns health status of the API.
 *
 * @param _req - Express request object
 * @param res - Express response object
 * @returns Health check response
 */
function getHealth(_req: Request, res: Response<HealthResponse>): void {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '1.0.0',
  });
}

healthRouter.get('/', getHealth);

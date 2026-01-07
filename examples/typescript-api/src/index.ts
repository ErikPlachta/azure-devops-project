import express, { Application } from 'express';
import { healthRouter } from './routes/health';
import { calculatorRouter } from './routes/calculator';

const app: Application = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use('/health', healthRouter);
app.use('/api/calculator', calculatorRouter);

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default app;

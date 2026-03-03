import express from 'express';
import cors from 'cors';
import 'dotenv/config';
import authRoutes from './routes/auth.routes';
import cycleRoutes from './routes/cycle.routes';
import dailyLogRoutes from './routes/dailyLog.routes';
import coupleRoutes from './routes/couple.routes';

const app = express();
const port = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/cycles', cycleRoutes);
app.use('/api/logs', dailyLogRoutes);
app.use('/api/couple', coupleRoutes);

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'healthy', service: 'FemControl API', timestamp: new Date() });
});

// 404 handler
app.use((_req, res) => {
    res.status(404).json({ success: false, message: 'Ruta no encontrada' });
});

if (require.main === module) {
    app.listen(Number(port), '0.0.0.0', () => {
        console.log(`[FemControl] Backend running on http://192.168.1.63:${port}`);
    });
}

export default app;

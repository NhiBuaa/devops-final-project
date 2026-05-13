const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json());

// Cấu hình Database kết nối tới PostgreSQL StatefulSet
const pool = new Pool({
    host: process.env.DB_HOST || 'postgres-service',
    user: process.env.DB_USER || 'appuser',
    password: process.env.DB_PASSWORD || 'password',
    database: process.env.DB_NAME || 'appdb',
    port: 5432,
});

// Kiểm tra kết nối DB khi khởi động
pool.on('connect', () => console.log(' Connected to PostgreSQL'));

// 1. Health Check (Dành cho K8s Liveness/Readiness Probe)
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'UP', timestamp: new Date() });
});

app.get('/healthz', (req, res) => {
    res.status(200).json({ status: 'UP', timestamp: new Date() });
});

app.get('/api/healthz', (req, res) => {
    res.status(200).json({ status: 'UP', timestamp: new Date() });
});

// 2. CRUD: Get all members
app.get('/api/members', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM members ORDER BY id ASC');
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 3. CRUD: Create member
app.post('/api/members', async (req, res) => {
    const { name, role } = req.body;
    try {
        const result = await pool.query(
            'INSERT INTO members (name, role) VALUES ($1, $2) RETURNING *',
            [name, role]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 4. CRUD: Update member
app.put('/api/members/:id', async (req, res) => {
    const { id } = req.params;
    const { name, role } = req.body;
    try {
        const result = await pool.query(
            'UPDATE members SET name = $1, role = $2 WHERE id = $3 RETURNING *',
            [name, role, id]
        );
        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 5. CRUD: Delete member
app.delete('/api/members/:id', async (req, res) => {
    const { id } = req.params;
    try {
        await pool.query('DELETE FROM members WHERE id = $1', [id]);
        res.status(204).send();
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const server = app.listen(PORT, () => {
    console.log(`🚀 Backend is running on port ${PORT}`);
});

// Graceful Shutdown cho Kubernetes
const shutdown = (signal) => {
    console.log(`${signal} signal received: starting graceful shutdown`);

    // Drop idle keep-alive sockets first so rollouts don't hang on old replicas.
    if (typeof server.closeIdleConnections === 'function') {
        server.closeIdleConnections();
    }
    if (typeof server.closeAllConnections === 'function') {
        server.closeAllConnections();
    }

    const forceExitTimer = setTimeout(() => {
        console.error('Graceful shutdown timed out, forcing process exit');
        process.exit(1);
    }, 10000);
    forceExitTimer.unref();

    server.close((err) => {
        if (err) {
            console.error('HTTP server close error:', err);
        }

        pool.end(() => {
            clearTimeout(forceExitTimer);
            console.log('HTTP server and database pool closed');
            process.exit(0);
        });
    });
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

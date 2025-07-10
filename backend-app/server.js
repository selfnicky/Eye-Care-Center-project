const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Basic health check endpoint
app.get('/health', (req, res) => {
    res.status(200).send('Backend is healthy!');
});

// Simple example endpoint for appointments (no actual DB interaction here)
app.get('/api/appointments', (req, res) => {
    // In a real app, this would query the database
    const appointments = [
        { id: 1, date: '2025-07-15', time: '10:00 AM', patient: 'John Doe' },
        { id: 2, date: '2025-07-16', time: '02:00 PM', patient: 'Jane Smith' }
    ];
    res.json(appointments);
});

// Database connection details from environment variables (Kubernetes Secrets will inject these)
const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_USER = process.env.DB_USER || 'admin';
const DB_PASSWORD = process.env.DB_PASSWORD || 'password';
const DB_NAME = process.env.DB_NAME || 'eyecaredb';

console.log(`Attempting to connect to DB: ${DB_USER}@${DB_HOST}/${DB_NAME}`);
// In a real application, you'd establish a database connection here
// Example (using pg for PostgreSQL, conceptually):
// const { Pool } = require('pg');
// const pool = new Pool({
//     host: DB_HOST,
//     user: DB_USER,
//     password: DB_PASSWORD,
//     database: DB_NAME,
//     port: 5432, // Default PostgreSQL port
// });
// pool.query('SELECT NOW()', (err, res) => {
//     if (err) {
//         console.error('Database connection error:', err.stack);
//     } else {
//         console.log('Database connected successfully:', res.rows[0]);
//     }
// });


app.listen(port, () => {
    console.log(`Backend server listening on port ${port}`);
});
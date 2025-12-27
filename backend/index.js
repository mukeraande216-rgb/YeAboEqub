const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// 1. GET: Fetch members who haven't won yet (For the Wheel)
app.get('/members', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, full_name FROM equb_members WHERE has_won = FALSE');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 2. GET: Fetch winners only (For the History Tab)
app.get('/winners', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT full_name, draw_date FROM equb_members WHERE has_won = TRUE ORDER BY draw_date DESC'
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 3. POST: Mark a specific winner
app.post('/mark-winner', async (req, res) => {
  const { id } = req.body;
  try {
    await pool.query(
      'UPDATE equb_members SET has_won = TRUE, draw_date = NOW() WHERE id = $1',
      [id]
    );
    res.json({ message: 'Winner marked successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 4. POST: Add a new member (From the App)
app.post('/add-member', async (req, res) => {
  const { full_name } = req.body;
  try {
    await pool.query('INSERT INTO equb_members (full_name) VALUES ($1)', [full_name]);
    res.json({ message: 'Member added successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 5. POST: Reset the entire cycle
app.post('/reset-cycle', async (req, res) => {
  try {
    await pool.query('UPDATE equb_members SET has_won = FALSE, draw_date = NULL');
    res.json({ message: 'Cycle reset successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 10000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}`);
});
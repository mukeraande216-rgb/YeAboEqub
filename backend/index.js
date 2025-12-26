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

// GET: Fetch members who haven't won yet
app.get('/members', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, full_name FROM equb_members WHERE has_won = FALSE');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST: Reset the entire cycle
app.post('/reset-cycle', async (req, res) => {
  try {
    await pool.query('UPDATE equb_members SET has_won = FALSE, draw_date = NULL');
    res.json({ message: 'Cycle reset successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
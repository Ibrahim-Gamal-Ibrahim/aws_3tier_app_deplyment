const express = require("express");
const { Pool } = require("pg");

const app = express();

app.use(express.json());

const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    ssl: {
        rejectUnauthorized: false
    }
});

async function initDatabase() {
    await pool.query(`
        CREATE TABLE IF NOT EXISTS todos (
            id SERIAL PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            completed BOOLEAN DEFAULT FALSE
        )
    `);

    console.log("Database initialized");
}

app.get("/health", async (req, res) => {
    try {
        await pool.query("SELECT 1");
        res.status(200).send("healthy");
    } catch (err) {
        console.error(err);
        res.status(500).send("database unavailable");
    }
});

app.get("/api/todos", async (req, res) => {
    try {
        const result = await pool.query(
            "SELECT * FROM todos ORDER BY id"
        );

        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});

app.post("/api/todos", async (req, res) => {
    try {
        const { title } = req.body;

        const result = await pool.query(
            "INSERT INTO todos (title) VALUES ($1) RETURNING *",
            [title]
        );

        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});

app.put("/api/todos/:id", async (req, res) => {
    try {
        const { id } = req.params;
        const { title, completed } = req.body;

        const result = await pool.query(
            `UPDATE todos
             SET title = $1,
                 completed = $2
             WHERE id = $3
             RETURNING *`,
            [title, completed, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "Todo not found" });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});

app.delete("/api/todos/:id", async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            "DELETE FROM todos WHERE id = $1 RETURNING *",
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "Todo not found" });
        }

        res.json({
            message: "Todo deleted",
            todo: result.rows[0]
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});

const PORT = 3000;

initDatabase()
    .then(() => {
        app.listen(PORT, "0.0.0.0", () => {
            console.log(`Backend listening on port ${PORT}`);
        });
    })
    .catch((err) => {
        console.error("Database initialization failed:", err);
        process.exit(1);
    });
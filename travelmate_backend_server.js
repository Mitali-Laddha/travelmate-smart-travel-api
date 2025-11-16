// =====================================================
// TravelMate Backend Server
// Node.js + Express + MySQL
// =====================================================

const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();

// =====================================================
// Middleware
// =====================================================
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging middleware
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// =====================================================
// Database Connection Pool
// =====================================================
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: 'ananyatravel',
    password: 'root123',
    database: 'travelmate_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0
});

// Test database connection
pool.getConnection()
    .then(connection => {
        console.log('✓ Database connected successfully');
        console.log('  User: ananyatravel');
        console.log('  Database: travelmate_db');
        connection.release();
    })
    .catch(err => {
        console.error('✗ Database connection failed:', err.message);
        console.error('  Please check MySQL is running and credentials are correct');
    });

// =====================================================
// JWT Secret
// =====================================================
const JWT_SECRET = process.env.JWT_SECRET || 'travelmate_secret_key_2024';

// =====================================================
// Authentication Middleware
// =====================================================
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid or expired token' });
        }
        req.user = user;
        next();
    });
};

// =====================================================
// AUTHENTICATION ROUTES
// =====================================================

// Register new user
app.post('/api/users/register', async (req, res) => {
    try {
        const { name, email, password, phone } = req.body;

        // Validate input
        if (!name || !email || !password) {
            return res.status(400).json({ error: 'Name, email, and password are required' });
        }

        // Check if user exists
        const [existing] = await pool.query(
            'SELECT * FROM users WHERE email = ?',
            [email]
        );

        if (existing.length > 0) {
            return res.status(400).json({ error: 'Email already registered' });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Insert user
        const [result] = await pool.query(
            'INSERT INTO users (name, email, password, phone) VALUES (?, ?, ?, ?)',
            [name, email, hashedPassword, phone || null]
        );

        // Generate token
        const token = jwt.sign(
            { id: result.insertId, name, email },
            JWT_SECRET,
            { expiresIn: '30d' }
        );

        res.status(201).json({
            message: 'User registered successfully',
            user_id: result.insertId,
            name,
            email,
            token
        });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ error: 'Server error during registration' });
    }
});

// Login user
app.post('/api/users/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password required' });
        }

        // Find user
        const [users] = await pool.query(
            'SELECT * FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const user = users[0];

        // Verify password
        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        // Update last login
        await pool.query(
            'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = ?',
            [user.id]
        );

        // Generate token
        const token = jwt.sign(
            { id: user.id, name: user.name, email: user.email },
            JWT_SECRET,
            { expiresIn: '30d' }
        );

        res.json({
            message: 'Login successful',
            user_id: user.id,
            name: user.name,
            email: user.email,
            token
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Server error during login' });
    }
});

// Get user profile
app.get('/api/users/:id', authenticateToken, async (req, res) => {
    try {
        const [users] = await pool.query(
            'SELECT id, name, email, phone, created_at FROM users WHERE id = ?',
            [req.params.id]
        );

        if (users.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json(users[0]);
    } catch (error) {
        console.error('Error fetching user:', error);
        res.status(500).json({ error: 'Failed to fetch user profile' });
    }
});

// =====================================================
// DESTINATIONS ROUTES
// =====================================================

// Get all destinations
app.get('/api/destinations', async (req, res) => {
    try {
        const { category, search, minCost, maxCost } = req.query;
        
        let query = `
            SELECT d.*, 
                   COUNT(DISTINCT da.id) AS activity_count,
                   COUNT(DISTINCT r.id) AS review_count
            FROM destinations d
            LEFT JOIN destination_activities da ON d.id = da.destination_id
            LEFT JOIN reviews r ON d.id = r.destination_id
            WHERE 1=1
        `;
        const params = [];

        if (category && category !== 'all') {
            query += ' AND d.category = ?';
            params.push(category);
        }

        if (search) {
            query += ' AND (d.name LIKE ? OR d.description LIKE ?)';
            params.push(`%${search}%`, `%${search}%`);
        }

        if (minCost) {
            query += ' AND d.avg_cost >= ?';
            params.push(minCost);
        }

        if (maxCost) {
            query += ' AND d.avg_cost <= ?';
            params.push(maxCost);
        }

        query += ' GROUP BY d.id ORDER BY d.popular DESC, d.rating DESC';

        const [destinations] = await pool.query(query, params);
        res.json(destinations);
    } catch (error) {
        console.error('Error fetching destinations:', error);
        res.status(500).json({ error: 'Failed to fetch destinations' });
    }
});

// Get single destination with activities
app.get('/api/destinations/:id', async (req, res) => {
    try {
        const [destinations] = await pool.query(
            'SELECT * FROM destinations WHERE id = ?',
            [req.params.id]
        );

        if (destinations.length === 0) {
            return res.status(404).json({ error: 'Destination not found' });
        }

        const destination = destinations[0];

        // Get activities
        const [activities] = await pool.query(
            'SELECT * FROM destination_activities WHERE destination_id = ? ORDER BY activity_type',
            [req.params.id]
        );

        // Get reviews
        const [reviews] = await pool.query(
            `SELECT r.*, u.name AS user_name 
             FROM reviews r 
             JOIN users u ON r.user_id = u.id 
             WHERE r.destination_id = ? 
             ORDER BY r.created_at DESC 
             LIMIT 10`,
            [req.params.id]
        );

        destination.activities = activities;
        destination.reviews = reviews;

        res.json(destination);
    } catch (error) {
        console.error('Error fetching destination:', error);
        res.status(500).json({ error: 'Failed to fetch destination details' });
    }
});

// Get popular destinations
app.get('/api/destinations/popular/list', async (req, res) => {
    try {
        const [destinations] = await pool.query(
            'SELECT * FROM destinations WHERE popular = TRUE ORDER BY rating DESC LIMIT 8'
        );
        res.json(destinations);
    } catch (error) {
        console.error('Error fetching popular destinations:', error);
        res.status(500).json({ error: 'Failed to fetch popular destinations' });
    }
});

// =====================================================
// TRIPS ROUTES
// =====================================================

// Get all trips for a user
app.get('/api/trips/user/:userId', async (req, res) => {
    try {
        const [trips] = await pool.query(
            `SELECT t.*, d.name AS destination_full_name, d.image_url AS destination_image
             FROM trips t
             LEFT JOIN destinations d ON t.destination_id = d.id
             WHERE t.user_id = ?
             ORDER BY t.created_at DESC`,
            [req.params.userId]
        );

        // Get itinerary for each trip
        for (let trip of trips) {
            const [itinerary] = await pool.query(
                'SELECT * FROM trip_itinerary WHERE trip_id = ? ORDER BY day_number, order_index',
                [trip.id]
            );
            trip.itinerary = itinerary;
        }

        res.json(trips);
    } catch (error) {
        console.error('Error fetching trips:', error);
        res.status(500).json({ error: 'Failed to fetch trips' });
    }
});

// Get single trip
app.get('/api/trips/:id', async (req, res) => {
    try {
        const [trips] = await pool.query(
            'SELECT * FROM trips WHERE id = ?',
            [req.params.id]
        );

        if (trips.length === 0) {
            return res.status(404).json({ error: 'Trip not found' });
        }

        const trip = trips[0];

        // Get itinerary
        const [itinerary] = await pool.query(
            'SELECT * FROM trip_itinerary WHERE trip_id = ? ORDER BY day_number, order_index',
            [trip.id]
        );

        trip.itinerary = itinerary;

        res.json(trip);
    } catch (error) {
        console.error('Error fetching trip:', error);
        res.status(500).json({ error: 'Failed to fetch trip' });
    }
});

// Create new trip
app.post('/api/trips', async (req, res) => {
    const connection = await pool.getConnection();
    
    try {
        await connection.beginTransaction();

        const {
            user_id,
            destination_id,
            trip_name,
            destination_name,
            start_date,
            num_days,
            budget,
            itinerary
        } = req.body;

        // Insert trip
        const [result] = await connection.query(
            `INSERT INTO trips 
             (user_id, destination_id, trip_name, destination_name, start_date, num_days,
              budget_flights, budget_hotel, budget_food, budget_activities, budget_transport, budget_misc)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                user_id,
                destination_id || null,
                trip_name,
                destination_name,
                start_date,
                num_days,
                budget.flights || 0,
                budget.hotel || 0,
                budget.food || 0,
                budget.activities || 0,
                budget.transport || 0,
                budget.misc || 0
            ]
        );

        const tripId = result.insertId;

        // Insert itinerary items
        if (itinerary) {
            for (let [dayKey, activities] of Object.entries(itinerary)) {
                const dayNumber = parseInt(dayKey.replace('day', ''));
                
                for (let i = 0; i < activities.length; i++) {
                    const activity = activities[i];
                    await connection.query(
                        `INSERT INTO trip_itinerary 
                         (trip_id, day_number, activity_name, activity_time, activity_notes, order_index)
                         VALUES (?, ?, ?, ?, ?, ?)`,
                        [
                            tripId,
                            dayNumber,
                            activity.name,
                            activity.time || null,
                            activity.notes || null,
                            i
                        ]
                    );
                }
            }
        }

        await connection.commit();

        res.status(201).json({
            message: 'Trip created successfully',
            trip_id: tripId
        });
    } catch (error) {
        await connection.rollback();
        console.error('Error creating trip:', error);
        res.status(500).json({ error: 'Failed to create trip' });
    } finally {
        connection.release();
    }
});

// Update trip
app.put('/api/trips/:id', async (req, res) => {
    const connection = await pool.getConnection();
    
    try {
        await connection.beginTransaction();

        const {
            trip_name,
            destination_name,
            start_date,
            num_days,
            budget,
            itinerary,
            status
        } = req.body;

        // Update trip
        await connection.query(
            `UPDATE trips SET 
             trip_name = ?, destination_name = ?, start_date = ?, num_days = ?,
             budget_flights = ?, budget_hotel = ?, budget_food = ?, 
             budget_activities = ?, budget_transport = ?, budget_misc = ?,
             status = ?,
             updated_at = CURRENT_TIMESTAMP
             WHERE id = ?`,
            [
                trip_name,
                destination_name,
                start_date,
                num_days,
                budget.flights || 0,
                budget.hotel || 0,
                budget.food || 0,
                budget.activities || 0,
                budget.transport || 0,
                budget.misc || 0,
                status || 'planning',
                req.params.id
            ]
        );

        // Delete old itinerary
        await connection.query('DELETE FROM trip_itinerary WHERE trip_id = ?', [req.params.id]);

        // Insert new itinerary
        if (itinerary) {
            for (let [dayKey, activities] of Object.entries(itinerary)) {
                const dayNumber = parseInt(dayKey.replace('day', ''));
                
                for (let i = 0; i < activities.length; i++) {
                    const activity = activities[i];
                    await connection.query(
                        `INSERT INTO trip_itinerary 
                         (trip_id, day_number, activity_name, activity_time, activity_notes, order_index)
                         VALUES (?, ?, ?, ?, ?, ?)`,
                        [
                            req.params.id,
                            dayNumber,
                            activity.name,
                            activity.time || null,
                            activity.notes || null,
                            i
                        ]
                    );
                }
            }
        }

        await connection.commit();

        res.json({ message: 'Trip updated successfully' });
    } catch (error) {
        await connection.rollback();
        console.error('Error updating trip:', error);
        res.status(500).json({ error: 'Failed to update trip' });
    } finally {
        connection.release();
    }
});

// Delete trip
app.delete('/api/trips/:id', async (req, res) => {
    try {
        const [result] = await pool.query(
            'DELETE FROM trips WHERE id = ?',
            [req.params.id]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Trip not found' });
        }

        res.json({ message: 'Trip deleted successfully' });
    } catch (error) {
        console.error('Error deleting trip:', error);
        res.status(500).json({ error: 'Failed to delete trip' });
    }
});

// =====================================================
// SAVED DESTINATIONS ROUTES
// =====================================================

// Get saved destinations for user
app.get('/api/saved/:userId', async (req, res) => {
    try {
        const [saved] = await pool.query(
            `SELECT d.*, sd.created_at AS saved_at
             FROM saved_destinations sd
             JOIN destinations d ON sd.destination_id = d.id
             WHERE sd.user_id = ?
             ORDER BY sd.created_at DESC`,
            [req.params.userId]
        );
        res.json(saved);
    } catch (error) {
        console.error('Error fetching saved destinations:', error);
        res.status(500).json({ error: 'Failed to fetch saved destinations' });
    }
});

// Save destination
app.post('/api/saved', async (req, res) => {
    try {
        const { user_id, destination_id } = req.body;

        await pool.query(
            'INSERT INTO saved_destinations (user_id, destination_id) VALUES (?, ?)',
            [user_id, destination_id]
        );

        res.status(201).json({ message: 'Destination saved successfully' });
    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(400).json({ error: 'Destination already saved' });
        }
        console.error('Error saving destination:', error);
        res.status(500).json({ error: 'Failed to save destination' });
    }
});

// Remove saved destination
app.delete('/api/saved/:userId/:destinationId', async (req, res) => {
    try {
        await pool.query(
            'DELETE FROM saved_destinations WHERE user_id = ? AND destination_id = ?',
            [req.params.userId, req.params.destinationId]
        );

        res.json({ message: 'Destination removed from saved list' });
    } catch (error) {
        console.error('Error removing saved destination:', error);
        res.status(500).json({ error: 'Failed to remove destination' });
    }
});

// =====================================================
// REVIEWS ROUTES
// =====================================================

// Get reviews for destination
app.get('/api/reviews/destination/:destinationId', async (req, res) => {
    try {
        const [reviews] = await pool.query(
            `SELECT r.*, u.name AS user_name
             FROM reviews r
             JOIN users u ON r.user_id = u.id
             WHERE r.destination_id = ?
             ORDER BY r.created_at DESC`,
            [req.params.destinationId]
        );
        res.json(reviews);
    } catch (error) {
        console.error('Error fetching reviews:', error);
        res.status(500).json({ error: 'Failed to fetch reviews' });
    }
});

// Add review
app.post('/api/reviews', async (req, res) => {
    try {
        const { user_id, destination_id, trip_id, rating, review_title, review_text, visit_date } = req.body;

        const [result] = await pool.query(
            `INSERT INTO reviews 
             (user_id, destination_id, trip_id, rating, review_title, review_text, visit_date)
             VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [user_id, destination_id, trip_id || null, rating, review_title, review_text, visit_date]
        );

        res.status(201).json({
            message: 'Review added successfully',
            review_id: result.insertId
        });
    } catch (error) {
        console.error('Error adding review:', error);
        res.status(500).json({ error: 'Failed to add review' });
    }
});

// =====================================================
// STATISTICS ROUTES
// =====================================================

// Get user statistics
app.get('/api/stats/user/:userId', async (req, res) => {
    try {
        const [stats] = await pool.query(
            'SELECT * FROM user_statistics WHERE id = ?',
            [req.params.userId]
        );

        res.json(stats[0] || {});
    } catch (error) {
        console.error('Error fetching user stats:', error);
        res.status(500).json({ error: 'Failed to fetch statistics' });
    }
});

// Get dashboard stats
app.get('/api/stats/dashboard', async (req, res) => {
    try {
        const [totalUsers] = await pool.query('SELECT COUNT(*) as count FROM users');
        const [totalTrips] = await pool.query('SELECT COUNT(*) as count FROM trips');
        const [totalDestinations] = await pool.query('SELECT COUNT(*) as count FROM destinations');
        const [totalReviews] = await pool.query('SELECT COUNT(*) as count FROM reviews');

        res.json({
            total_users: totalUsers[0].count,
            total_trips: totalTrips[0].count,
            total_destinations: totalDestinations[0].count,
            total_reviews: totalReviews[0].count
        });
    } catch (error) {
        console.error('Error fetching dashboard stats:', error);
        res.status(500).json({ error: 'Failed to fetch dashboard statistics' });
    }
});

// =====================================================
// HEALTH CHECK ROUTE
// =====================================================
app.get('/api/health', async (req, res) => {
    try {
        await pool.query('SELECT 1');
        res.json({ 
            status: 'healthy', 
            database: 'connected',
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({ 
            status: 'unhealthy', 
            database: 'disconnected',
            error: error.message 
        });
    }
});

// =====================================================
// ERROR HANDLING
// =====================================================
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ 
        error: 'Something went wrong!',
        message: err.message 
    });
});

// 404 Handler
app.use((req, res) => {
    res.status(404).json({ error: 'Route not found' });
});

// =====================================================
// START SERVER
// =====================================================
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`
╔════════════════════════════════════════════════╗
║        TravelMate Backend Server               ║
╠════════════════════════════════════════════════╣
║  Status: Running                               ║
║  Port: ${PORT}                                    ║
║  Database: travelmate_db                       ║
║  User: ananyatravel                            ║
║  API Docs: http://localhost:${PORT}/api         ║
╚════════════════════════════════════════════════╝
    `);
});

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('\nShutting down gracefully...');
    await pool.end();
    process.exit(0);
});
-- =====================================================
-- TravelMate Database Schema
-- MySQL Database for Smart Travel Companion App
-- =====================================================

-- Create Database
DROP DATABASE IF EXISTS travelmate_db;
CREATE DATABASE travelmate_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE travelmate_db;

-- =====================================================
-- Table: users
-- Stores user account information
-- =====================================================
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(15),
    profile_image VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_email (email),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB;

-- =====================================================
-- Table: destinations
-- Stores information about travel destinations
-- =====================================================
CREATE TABLE destinations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    category ENUM('beach', 'mountain', 'cultural', 'adventure', 'urban', 'wildlife') NOT NULL,
    country VARCHAR(100) DEFAULT 'India',
    state VARCHAR(100),
    description TEXT,
    image_url VARCHAR(500),
    rating DECIMAL(2,1) DEFAULT 0.0,
    duration VARCHAR(50),
    best_time VARCHAR(100),
    avg_cost DECIMAL(10,2) DEFAULT 0,
    popular BOOLEAN DEFAULT FALSE,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_popular (popular),
    INDEX idx_name (name),
    FULLTEXT KEY ft_search (name, description)
) ENGINE=InnoDB;

-- =====================================================
-- Table: destination_activities
-- Stores popular activities for each destination
-- =====================================================
CREATE TABLE destination_activities (
    id INT PRIMARY KEY AUTO_INCREMENT,
    destination_id INT NOT NULL,
    activity_name VARCHAR(200) NOT NULL,
    activity_type ENUM('sightseeing', 'adventure', 'cultural', 'relaxation', 'shopping', 'food', 'nightlife') DEFAULT 'sightseeing',
    estimated_cost DECIMAL(10,2) DEFAULT 0,
    duration_hours INT DEFAULT 2,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE CASCADE,
    INDEX idx_destination (destination_id),
    INDEX idx_type (activity_type)
) ENGINE=InnoDB;

-- =====================================================
-- Table: trips
-- Stores user trip plans
-- =====================================================
CREATE TABLE trips (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    destination_id INT,
    trip_name VARCHAR(200) NOT NULL,
    destination_name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    num_days INT NOT NULL DEFAULT 1,
    status ENUM('planning', 'confirmed', 'completed', 'cancelled') DEFAULT 'planning',
    
    -- Budget breakdown
    budget_flights DECIMAL(10,2) DEFAULT 0,
    budget_hotel DECIMAL(10,2) DEFAULT 0,
    budget_food DECIMAL(10,2) DEFAULT 0,
    budget_activities DECIMAL(10,2) DEFAULT 0,
    budget_transport DECIMAL(10,2) DEFAULT 0,
    budget_misc DECIMAL(10,2) DEFAULT 0,
    budget_total DECIMAL(10,2) GENERATED ALWAYS AS (
        budget_flights + budget_hotel + budget_food + 
        budget_activities + budget_transport + budget_misc
    ) STORED,
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_destination_id (destination_id),
    INDEX idx_start_date (start_date),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- =====================================================
-- Table: trip_itinerary
-- Stores day-wise itinerary for each trip
-- =====================================================
CREATE TABLE trip_itinerary (
    id INT PRIMARY KEY AUTO_INCREMENT,
    trip_id INT NOT NULL,
    day_number INT NOT NULL,
    activity_name VARCHAR(200) NOT NULL,
    activity_time TIME,
    activity_notes TEXT,
    estimated_cost DECIMAL(10,2) DEFAULT 0,
    location VARCHAR(200),
    order_index INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
    INDEX idx_trip_id (trip_id),
    INDEX idx_day_number (day_number),
    INDEX idx_order (order_index)
) ENGINE=InnoDB;

-- =====================================================
-- Table: bookings
-- Stores flight/hotel bookings
-- =====================================================
CREATE TABLE bookings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    trip_id INT NOT NULL,
    user_id INT NOT NULL,
    booking_type ENUM('flight', 'hotel', 'activity', 'transport') NOT NULL,
    booking_reference VARCHAR(100),
    provider_name VARCHAR(200),
    booking_date DATE,
    booking_time TIME,
    amount DECIMAL(10,2) DEFAULT 0,
    status ENUM('pending', 'confirmed', 'cancelled') DEFAULT 'pending',
    details JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_trip_id (trip_id),
    INDEX idx_user_id (user_id),
    INDEX idx_type (booking_type),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- =====================================================
-- Table: user_preferences
-- Stores user travel preferences
-- =====================================================
CREATE TABLE user_preferences (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL UNIQUE,
    preferred_categories JSON,
    budget_range_min DECIMAL(10,2) DEFAULT 0,
    budget_range_max DECIMAL(10,2) DEFAULT 100000,
    preferred_duration_days INT DEFAULT 3,
    travel_style ENUM('budget', 'moderate', 'luxury') DEFAULT 'moderate',
    currency VARCHAR(10) DEFAULT 'INR',
    language VARCHAR(10) DEFAULT 'en',
    notifications_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- Table: reviews
-- Stores user reviews for destinations
-- =====================================================
CREATE TABLE reviews (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    destination_id INT NOT NULL,
    trip_id INT,
    rating DECIMAL(2,1) NOT NULL CHECK (rating >= 0 AND rating <= 5),
    review_title VARCHAR(200),
    review_text TEXT,
    visit_date DATE,
    helpful_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE CASCADE,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE SET NULL,
    INDEX idx_destination_id (destination_id),
    INDEX idx_user_id (user_id),
    INDEX idx_rating (rating)
) ENGINE=InnoDB;

-- =====================================================
-- Table: saved_destinations
-- Stores user's saved/favorite destinations
-- =====================================================
CREATE TABLE saved_destinations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    destination_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE CASCADE,
    UNIQUE KEY unique_save (user_id, destination_id),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB;

-- =====================================================
-- Insert Sample Data
-- =====================================================

-- Sample Users (password is 'password123' hashed with bcrypt)
INSERT INTO users (name, email, password, phone) VALUES
('Ananya Sharma', 'ananya@travelmate.com', '$2a$10$rXVXvXvXvXvXvXvXvXvXveuqG0JYvXMkXvXvXvXvXvXvXvXvXvXvXvX', '9876543210'),
('Demo User', 'demo@travelmate.com', '$2a$10$rXVXvXvXvXvXvXvXvXvXveuqG0JYvXMkXvXvXvXvXvXvXvXvXvXvXvX', '9876543211'),
('Rahul Kumar', 'rahul@example.com', '$2a$10$rXVXvXvXvXvXvXvXvXvXveuqG0JYvXMkXvXvXvXvXvXvXvXvXvXvXvX', '9876543212');

-- Sample Destinations
INSERT INTO destinations (name, category, state, description, image_url, rating, duration, best_time, avg_cost, popular, latitude, longitude) VALUES
('Goa', 'beach', 'Goa', 'Sun, sand, and sea - the perfect beach paradise with vibrant nightlife', 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=500', 4.8, '3-5 days', 'November to February', 15000, TRUE, 15.2993, 74.1240),
('Manali', 'mountain', 'Himachal Pradesh', 'Breathtaking Himalayan views, adventure activities, and serene landscapes', 'https://images.unsplash.com/photo-1626621341517-4364f6c739c8?w=500', 4.7, '4-6 days', 'March to June', 18000, TRUE, 32.2396, 77.1887),
('Jaipur', 'cultural', 'Rajasthan', 'The Pink City - Rich heritage, majestic forts, and royal palaces', 'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=500', 4.6, '2-3 days', 'October to March', 12000, TRUE, 26.9124, 75.7873),
('Ladakh', 'adventure', 'Ladakh', 'Land of high passes - Adventure, monasteries, and stunning landscapes', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500', 4.9, '7-10 days', 'May to September', 35000, TRUE, 34.1526, 77.5771),
('Kerala', 'beach', 'Kerala', 'Gods Own Country - Backwaters, beaches, and lush greenery', 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=500', 4.7, '5-7 days', 'September to March', 20000, FALSE, 10.8505, 76.2711),
('Udaipur', 'cultural', 'Rajasthan', 'City of Lakes - Romantic palaces, beautiful lakes, and rich culture', 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=500', 4.8, '2-3 days', 'September to March', 14000, FALSE, 24.5854, 73.7125),
('Rishikesh', 'adventure', 'Uttarakhand', 'Yoga capital and adventure hub - Spiritual retreat with thrilling activities', 'https://images.unsplash.com/photo-1626092107797-36f3a6c423c3?w=500', 4.5, '3-4 days', 'September to November', 10000, FALSE, 30.0869, 78.2676),
('Shimla', 'mountain', 'Himachal Pradesh', 'Queen of Hills - Colonial charm, scenic beauty, and pleasant weather', 'https://images.unsplash.com/photo-1597074866923-dc0589150358?w=500', 4.4, '3-4 days', 'March to June', 13000, FALSE, 31.1048, 77.1734);

-- Sample Activities for Goa
INSERT INTO destination_activities (destination_id, activity_name, activity_type, estimated_cost, duration_hours, description) VALUES
(1, 'Beach Hopping', 'relaxation', 500, 4, 'Visit multiple beautiful beaches including Baga, Calangute, and Anjuna'),
(1, 'Water Sports', 'adventure', 1500, 2, 'Enjoy parasailing, jet skiing, and banana boat rides'),
(1, 'Fort Exploration', 'cultural', 300, 3, 'Explore historical Aguada and Chapora forts'),
(1, 'Night Markets', 'shopping', 1000, 3, 'Shop at vibrant flea markets and enjoy local food'),
(1, 'Cruise Party', 'nightlife', 2000, 4, 'Dance night away on a luxury cruise with dinner');

-- Sample Activities for Manali
INSERT INTO destination_activities (destination_id, activity_name, activity_type, estimated_cost, duration_hours, description) VALUES
(2, 'Rohtang Pass', 'sightseeing', 2000, 8, 'Visit the breathtaking high mountain pass'),
(2, 'Solang Valley', 'adventure', 1500, 5, 'Enjoy skiing, paragliding, and zorbing'),
(2, 'Trekking', 'adventure', 1000, 6, 'Trek through beautiful Himalayan trails'),
(2, 'River Rafting', 'adventure', 1200, 3, 'Experience thrilling white water rafting'),
(2, 'Paragliding', 'adventure', 2500, 1, 'Soar above the valleys with professional guides');

-- Sample Activities for Jaipur
INSERT INTO destination_activities (destination_id, activity_name, activity_type, estimated_cost, duration_hours, description) VALUES
(3, 'Amber Fort', 'cultural', 500, 3, 'Explore the magnificent hilltop fort'),
(3, 'City Palace', 'cultural', 400, 2, 'Visit the royal residence with museums'),
(3, 'Hawa Mahal', 'cultural', 200, 1, 'See the iconic Palace of Winds'),
(3, 'Local Markets', 'shopping', 1500, 4, 'Shop for traditional jewelry, textiles, and handicrafts'),
(3, 'Camel Ride', 'adventure', 600, 2, 'Enjoy a traditional camel safari');

-- Sample Activities for Ladakh
INSERT INTO destination_activities (destination_id, activity_name, activity_type, estimated_cost, duration_hours, description) VALUES
(4, 'Leh Palace', 'cultural', 300, 2, 'Visit the historic 17th-century palace'),
(4, 'Pangong Lake', 'sightseeing', 3000, 10, 'Visit the stunning high-altitude lake'),
(4, 'Nubra Valley', 'sightseeing', 2500, 8, 'Explore the valley of flowers with sand dunes'),
(4, 'Bike Trip', 'adventure', 5000, 10, 'Take an adventurous bike ride through mountain passes'),
(4, 'Monastery Tour', 'cultural', 500, 4, 'Visit ancient Buddhist monasteries');

-- Sample Trip
INSERT INTO trips (user_id, destination_id, trip_name, destination_name, start_date, end_date, num_days, status, 
                   budget_flights, budget_hotel, budget_food, budget_activities, budget_transport, budget_misc) VALUES
(1, 1, '5-Day Goa Beach Vacation', 'Goa', '2024-12-15', '2024-12-20', 5, 'planning', 
 8000, 10000, 5000, 7000, 3000, 2000);

-- Sample Itinerary for the trip
INSERT INTO trip_itinerary (trip_id, day_number, activity_name, activity_time, activity_notes, estimated_cost, order_index) VALUES
(1, 1, 'Arrive in Goa', '10:00:00', 'Flight from Delhi', 8000, 1),
(1, 1, 'Check-in at Hotel', '14:00:00', 'Beach-side resort', 0, 2),
(1, 1, 'Beach Walk and Dinner', '18:00:00', 'Baga Beach area', 1500, 3),
(1, 2, 'Water Sports', '09:00:00', 'Pre-booked package', 1500, 1),
(1, 2, 'Beach Hopping', '13:00:00', 'Visit Anjuna and Vagator', 500, 2),
(1, 2, 'Sunset at Chapora Fort', '17:00:00', 'Photography spot', 0, 3),
(1, 3, 'Fort Exploration', '09:00:00', 'Aguada Fort', 300, 1),
(1, 3, 'Local Markets', '15:00:00', 'Shopping for souvenirs', 1000, 2),
(1, 3, 'Night Market Visit', '20:00:00', 'Arpora Saturday Night Market', 1500, 3);

-- Sample Reviews
INSERT INTO reviews (user_id, destination_id, trip_id, rating, review_title, review_text, visit_date) VALUES
(1, 1, 1, 4.5, 'Amazing Beach Vacation', 'Had a wonderful time in Goa. The beaches are beautiful and the food is amazing!', '2024-12-20'),
(2, 2, NULL, 5.0, 'Manali is Heaven', 'The mountains, the snow, the adventure - everything was perfect. Highly recommended!', '2024-06-15'),
(3, 3, NULL, 4.0, 'Rich Cultural Experience', 'Jaipur offers a glimpse into royal history. The forts are magnificent.', '2024-01-20');

-- Sample Saved Destinations
INSERT INTO saved_destinations (user_id, destination_id) VALUES
(1, 2),
(1, 4),
(2, 1),
(2, 3);

-- =====================================================
-- Create Views for Quick Access
-- =====================================================

-- View: Trip Summary
CREATE OR REPLACE VIEW trip_summary AS
SELECT 
    t.id,
    t.trip_name,
    t.destination_name,
    t.start_date,
    t.end_date,
    t.num_days,
    t.status,
    t.budget_total,
    u.name AS user_name,
    u.email AS user_email,
    COUNT(DISTINCT ti.id) AS total_activities,
    d.rating AS destination_rating
FROM trips t
JOIN users u ON t.user_id = u.id
LEFT JOIN trip_itinerary ti ON t.id = ti.trip_id
LEFT JOIN destinations d ON t.destination_id = d.id
GROUP BY t.id;

-- View: Popular Destinations with Activity Count
CREATE OR REPLACE VIEW popular_destinations_view AS
SELECT 
    d.id,
    d.name,
    d.category,
    d.description,
    d.rating,
    d.avg_cost,
    d.duration,
    d.best_time,
    d.popular,
    COUNT(DISTINCT da.id) AS activity_count,
    COUNT(DISTINCT r.id) AS review_count,
    AVG(r.rating) AS avg_review_rating
FROM destinations d
LEFT JOIN destination_activities da ON d.id = da.destination_id
LEFT JOIN reviews r ON d.id = r.destination_id
GROUP BY d.id
ORDER BY d.popular DESC, d.rating DESC;

-- View: User Trip Statistics
CREATE OR REPLACE VIEW user_statistics AS
SELECT 
    u.id,
    u.name,
    u.email,
    COUNT(DISTINCT t.id) AS total_trips,
    SUM(t.budget_total) AS total_spent,
    AVG(t.num_days) AS avg_trip_duration,
    COUNT(DISTINCT r.id) AS total_reviews,
    AVG(r.rating) AS avg_rating_given
FROM users u
LEFT JOIN trips t ON u.id = t.user_id
LEFT JOIN reviews r ON u.id = r.user_id
GROUP BY u.id;

-- =====================================================
-- Stored Procedures
-- =====================================================

-- Procedure: Get Complete Trip Details
DELIMITER //
CREATE PROCEDURE GetTripDetails(IN tripId INT)
BEGIN
    -- Get trip info
    SELECT * FROM trips WHERE id = tripId;
    
    -- Get itinerary
    SELECT * FROM trip_itinerary 
    WHERE trip_id = tripId 
    ORDER BY day_number, order_index;
    
    -- Get bookings
    SELECT * FROM bookings WHERE trip_id = tripId;
END //
DELIMITER ;

-- Procedure: Get Destination with Activities
DELIMITER //
CREATE PROCEDURE GetDestinationDetails(IN destId INT)
BEGIN
    -- Get destination info
    SELECT * FROM destinations WHERE id = destId;
    
    -- Get activities
    SELECT * FROM destination_activities 
    WHERE destination_id = destId 
    ORDER BY activity_type, activity_name;
    
    -- Get recent reviews
    SELECT r.*, u.name AS user_name 
    FROM reviews r
    JOIN users u ON r.user_id = u.id
    WHERE r.destination_id = destId
    ORDER BY r.created_at DESC
    LIMIT 10;
END //
DELIMITER ;

-- Procedure: Calculate Trip Budget
DELIMITER //
CREATE PROCEDURE CalculateTripBudget(IN tripId INT)
BEGIN
    SELECT 
        budget_flights,
        budget_hotel,
        budget_food,
        budget_activities,
        budget_transport,
        budget_misc,
        budget_total,
        (SELECT SUM(estimated_cost) FROM trip_itinerary WHERE trip_id = tripId) AS actual_itinerary_cost
    FROM trips
    WHERE id = tripId;
END //
DELIMITER ;

-- Procedure: Search Destinations
DELIMITER //
CREATE PROCEDURE SearchDestinations(
    IN searchTerm VARCHAR(200),
    IN categoryFilter VARCHAR(50),
    IN minCost DECIMAL(10,2),
    IN maxCost DECIMAL(10,2)
)
BEGIN
    SELECT d.*, COUNT(DISTINCT da.id) AS activity_count
    FROM destinations d
    LEFT JOIN destination_activities da ON d.id = da.destination_id
    WHERE 
        (searchTerm IS NULL OR searchTerm = '' OR 
         d.name LIKE CONCAT('%', searchTerm, '%') OR 
         d.description LIKE CONCAT('%', searchTerm, '%'))
        AND (categoryFilter IS NULL OR categoryFilter = 'all' OR d.category = categoryFilter)
        AND d.avg_cost BETWEEN minCost AND maxCost
    GROUP BY d.id
    ORDER BY d.popular DESC, d.rating DESC;
END //
DELIMITER ;

-- =====================================================
-- Triggers
-- =====================================================

-- Trigger: Update destination rating when review is added
DELIMITER //
CREATE TRIGGER update_destination_rating AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    UPDATE destinations 
    SET rating = (
        SELECT AVG(rating) 
        FROM reviews 
        WHERE destination_id = NEW.destination_id
    )
    WHERE id = NEW.destination_id;
END //
DELIMITER ;

-- Trigger: Set end_date automatically based on num_days
DELIMITER //
CREATE TRIGGER set_trip_end_date BEFORE INSERT ON trips
FOR EACH ROW
BEGIN
    IF NEW.end_date IS NULL AND NEW.start_date IS NOT NULL THEN
        SET NEW.end_date = DATE_ADD(NEW.start_date, INTERVAL NEW.num_days - 1 DAY);
    END IF;
END //
DELIMITER ;

-- =====================================================
-- Indexes for Performance
-- =====================================================

CREATE INDEX idx_trip_dates ON trips(start_date, end_date);
CREATE INDEX idx_destination_cost ON destinations(avg_cost);
CREATE INDEX idx_itinerary_composite ON trip_itinerary(trip_id, day_number, order_index);
CREATE INDEX idx_reviews_destination_rating ON reviews(destination_id, rating);

-- =====================================================
-- Grant Permissions to User
-- =====================================================

-- Create user if not exists
CREATE USER IF NOT EXISTS 'ananyatravel'@'localhost' IDENTIFIED BY 'root123';

-- Grant all privileges on travelmate_db
GRANT ALL PRIVILEGES ON travelmate_db.* TO 'ananyatravel'@'localhost';

-- Flush privileges
FLUSH PRIVILEGES;

-- =====================================================
-- Verification Queries
-- =====================================================

-- Show all tables
SHOW TABLES;

-- Show table structures
DESCRIBE users;
DESCRIBE destinations;
DESCRIBE trips;

-- Sample verification queries
SELECT 'Database created successfully!' AS message;
SELECT COUNT(*) AS total_destinations FROM destinations;
SELECT COUNT(*) AS total_users FROM users;
SELECT COUNT(*) AS total_trips FROM trips;

-- Display sample data
SELECT * FROM destinations LIMIT 5;
SELECT * FROM trip_summary;

COMMIT;
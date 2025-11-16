# TravelMate Backend Environment Configuration

# Server Configuration
PORT=3000
NODE_ENV=development

# MySQL Database Configuration
DB_HOST=localhost
DB_USER=ananyatravel
DB_PASSWORD=root123
DB_NAME=travelmate_db
DB_PORT=3306

# JWT Configuration
JWT_SECRET=travelmate_secret_key_2024_change_this_in_production

# CORS Configuration
CORS_ORIGIN=http://localhost:8080

# Session Configuration
SESSION_SECRET=travelmate_session_secret_2024

# API Keys (Optional - for future integrations)
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret

# Email Configuration (Optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_DIR=./uploads

# Logging
LOG_LEVEL=info
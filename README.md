# TravelMate — Backend API

**Project summary**
A Node.js + Express backend for *TravelMate — Smart Travel Companion*. Uses MySQL for data storage and supports user authentication with bcrypt + JWT.

**Detected files**
- travelmate_backend_server.js
- travelmate_db_schema.sql
- travelmate_enhanced.html
- travelmate_env_file.sh
- travelmate_package_json.json

---

## Quick start (local)

1. Install Node.js (v14+) and MySQL.
2. Copy environment variables into a `.env` file (there is a helper `travelmate_env_file.sh` included).
3. Install dependencies:
```bash
npm install
```
4. Initialize the database (adjust user/password as needed):
```bash
# using provided schema file
mysql -u your_db_user -p < travelmate_db_schema.sql
```
Or run the npm script if you set credentials to match:
```bash
npm run init-db
```
5. Start the server:
```bash
npm start
# or for development
npm run dev
```

## Files of interest
- `travelmate_backend_server.js` — main Express server implementation.
- `travelmate_package_json.json` — `package.json` metadata (renamed inside the upload).
- `travelmate_db_schema.sql` — SQL schema for MySQL.
- `travelmate_env_file.sh` — example environment variables.
- `travelmate_enhanced.html` — frontend/demo HTML page.

## Create a GitHub repository & push (commands)

```bash
# inside project root (where package.json is)
git init
git add .
git commit -m "Initial commit — TravelMate backend"
# create repo on GitHub website OR use GitHub CLI:
# gh repo create <your-username>/travelmate-backend --public --source=. --remote=origin --push
# OR add remote manually:
git remote add origin https://github.com/<your-username>/travelmate-backend.git
git branch -M main
git push -u origin main
```

If you use the GitHub website, create a new repository without README (so no merge needed), then follow the commands it shows.

## .env example
You can copy the included `travelmate_env_file.sh` into a `.env` file. Typical variables:
```
DB_HOST=localhost
DB_USER=your_mysql_user
DB_PASSWORD=your_password
DB_NAME=travelmate
JWT_SECRET=change_this_secret
PORT=3000
```

## .gitignore (recommended)
Node related:
```
node_modules/
.env
*.log
.DS_Store
coverage/
```

## License
Suggested: MIT. (A `LICENSE` file is included.)

---

If you'd like, I can:
- Create the GitHub repo for you (I can't push without your GitHub credentials) — I can generate the exact `gh` CLI command to run.
- Rename `travelmate_package_json.json` to `package.json` and place files into a ready-to-push folder. (I already prepared a zip `travelmate_repo.zip` you can download.)

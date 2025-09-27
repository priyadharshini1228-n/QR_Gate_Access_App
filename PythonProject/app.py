from flask import Flask, request, jsonify, send_file
from flask_mysqldb import MySQL
import MySQLdb.cursors
from werkzeug.security import generate_password_hash, check_password_hash
from cryptography.fernet import Fernet
from flask_cors import CORS
from datetime import datetime, timedelta
import uuid, io, qrcode, traceback, re

# ====================== APP CONFIG =========================
app = Flask(__name__)
app.secret_key = 'your_secret_key'

# MySQL configuration — update these if needed
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = 'Spm@12345'
app.config['MYSQL_DB'] = 'mydb'

mysql = MySQL(app)
# Allow cross-origin requests (dev) — restrict origins in production
CORS(app, resources={r"/api/*": {"origins": "*"}})

# Encryption key for QR codes
FERNET_KEY = b'RkM1tBaCso8pXjxjYL7Nc54AuZmmcuL3EeBI9CjjwV0='
fernet = Fernet(FERNET_KEY)

# ---------------------- Helper -----------------------------
def _json_error(message, code=400):
    return jsonify({"success": False, "message": message}), code

# ====================== AUTH ROUTES =========================

@app.route('/api/login', methods=['POST'])
def api_login():
    try:
        data = request.get_json(force=True)
        username = data.get('username')
        password = data.get('password')

        if not username or not password:
            return _json_error("username and password required", 400)

        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        cursor.execute('SELECT * FROM login_detail WHERE username = %s', (username,))
        account = cursor.fetchone()
        cursor.close()

        if account and check_password_hash(account['password'], password):
            user_id = account['user_id']
            is_admin = int(account.get('is_admin', 0))

            cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
            cursor.execute("SELECT qr FROM user_detail WHERE user_id = %s", (user_id,))
            qr_result = cursor.fetchone()
            cursor.close()

            return jsonify({
                "success": True,
                "user_id": user_id,
                "username": account['username'],
                "is_admin": is_admin,
                "has_qr": bool(qr_result and qr_result.get('qr'))
            }), 200

        return _json_error("Invalid username or password", 401)

    except Exception as e:
        traceback.print_exc()
        return _json_error(str(e), 500)

#===============================Registration============================
@app.route('/api/register', methods=['POST'])
def api_register():
    try:
        data = request.get_json(force=True)
        username = data.get('username')
        password = data.get('password')
        email = data.get('email')
        admin_key = data.get('admin_key')

        if not username or not password or not email:
            return _json_error("username, password and email are required", 400)

        is_admin = 1 if admin_key == 'your_admin_secret_key' else 0

        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        cursor.execute('SELECT * FROM register_details WHERE username = %s', (username,))
        if cursor.fetchone():
            cursor.close()
            return _json_error("Account already exists", 400)

        hashed_pw = generate_password_hash(password)
        cursor.execute(
            'INSERT INTO register_details (username, password, email_id, device_from, is_admin) VALUES (%s, %s, %s, %s, %s)',
            (username, hashed_pw, email, request.headers.get('User-Agent'), is_admin)
        )
        mysql.connection.commit()
        cursor.close()

        # Note: your DB trigger or external process should create login_detail row if needed.
        return jsonify({"success": True, "message": "Registered successfully"}), 201

    except Exception as e:
        traceback.print_exc()
        return _json_error(str(e), 500)

# ====================== USER FORM API =========================

@app.route('/api/user_form', methods=['POST'])
def api_user_form():
    try:
        data = request.get_json(force=True)

        user_id = data.get("user_id")
        fname = data.get("fname")
        lname = data.get("lname")
        gender = data.get("gender")
        contact_number = data.get("contact_number")
        email_id = data.get("email_id")
        address = data.get("address")

        if not all([user_id, fname, lname, gender, contact_number, email_id, address]):
            return _json_error("All fields are required", 400)

        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)

        # check if already exists
        cursor.execute("SELECT * FROM user_detail WHERE user_id = %s", (user_id,))
        if cursor.fetchone():
            cursor.close()
            return _json_error("User form already submitted", 400)

        # generate auth_token
        auth_token = str(uuid.uuid4())

        # build QR payload
        qr_payload = f"user_id:{user_id}|auth_token:{auth_token}"

        # encrypt payload
        encrypted = fernet.encrypt(qr_payload.encode()).decode()

        # generate QR image (PNG)
        qr_img = qrcode.make(encrypted)
        img_bytes = io.BytesIO()
        qr_img.save(img_bytes, format='PNG')
        qr_blob = img_bytes.getvalue()

        # insert into DB with QR as BLOB
        cursor.execute(
            """
            INSERT INTO user_detail 
                (user_id, fname, lname, gender, contact_number, email_id, address, auth_token, qr)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (user_id, fname, lname, gender, contact_number, email_id, address, auth_token, qr_blob)
        )
        mysql.connection.commit()
        cursor.close()

        return jsonify({
            "success": True,
            "message": "User form submitted successfully",
            "user_id": user_id
        }), 201

    except Exception as e:
        traceback.print_exc()
        return _json_error(str(e), 500)


# ====================== ADMIN ROUTES =========================

@app.route('/api/admin/logs', methods=['GET'])
def api_admin_logs():
    try:
        username = request.args.get('username', '')
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        log_type = request.args.get('log_type')
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 50))
        offset = (page - 1) * per_page

        query = """
            SELECT r.user_id, r.username, r.email_id, r.is_admin, e.log_type, e.entry_time
            FROM register_details r
            JOIN entry_logs e ON r.user_id = e.user_id
            WHERE 1=1
        """
        filters = []

        if username:
            query += " AND (r.username LIKE %s OR r.email_id LIKE %s)"
            filters.extend([f"%{username}%", f"%{username}%"])
        if start_date:
            query += " AND e.entry_time >= %s"
            filters.append(start_date)
        if end_date:
            query += " AND e.entry_time <= %s"
            filters.append(end_date)
        if log_type:
            query += " AND e.log_type = %s"
            filters.append(log_type)

        query += " ORDER BY e.entry_time DESC LIMIT %s OFFSET %s"
        filters.extend([per_page, offset])

        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        cursor.execute(query, filters)
        logs = cursor.fetchall()
        cursor.close()

        return jsonify({"success": True, "logs": logs}), 200

    except Exception as e:
        traceback.print_exc()
        return _json_error(str(e), 500)

@app.route("/admin/stats", methods=["GET"])
def admin_stats():
    stats = {
        "weekly_visitors": 120,
        "registered_users": 45,
        "registered_workers": 18
    }
    return jsonify(stats)

@app.route('/api/admin/dashboard', methods=['GET'])
def api_admin_dashboard():
    """
    Returns aggregate counts for the admin dashboard:
    - registered_users (non-admin)
    - registered_workers (admin flagged)
    - weekly_visitors (distinct users this week)
    """
    try:
        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)

        # Registered users (non-admin)
        cursor.execute('SELECT COUNT(*) AS count FROM register_details WHERE is_admin = 0')
        registered_users = int(cursor.fetchone()['count'])

        # Registered workers (admin = 1)
        cursor.execute('SELECT COUNT(*) AS count FROM register_details WHERE is_admin = 1')
        registered_workers = int(cursor.fetchone()['count'])

        # Weekly unique visitors
        cursor.execute("""
            SELECT COUNT(DISTINCT user_id) AS weekly_visitors
            FROM entry_logs
            WHERE YEARWEEK(entry_time, 1) = YEARWEEK(CURDATE(), 1)
        """)
        weekly_visitors = int(cursor.fetchone()['weekly_visitors'] or 0)

        # Weekly trend
        weekly_trend = []
        for i in range(7):
            day_start = (datetime.now() - timedelta(days=6 - i)).replace(hour=0, minute=0, second=0, microsecond=0)
            day_end = day_start + timedelta(days=1)

            cursor.execute(
                "SELECT COUNT(*) AS cnt FROM register_details WHERE created_date >= %s AND created_date < %s",
                (day_start, day_end)
            )
            result = cursor.fetchone()
            count = result['cnt'] if result else 0
            weekly_trend.append(count)

        cursor.close()

        return jsonify({
            "success": True,
            "data": {
                "registered_users": registered_users,
                "registered_workers": registered_workers,
                "weekly_visitors": weekly_visitors,
                "weekly_trend": weekly_trend
            }
        }), 200

    except Exception as e:
        traceback.print_exc()
        return _json_error(str(e), 500)

#===============================WeeklyVisitors============================

@app.route('/api/admin/weekly_visitors', methods=['GET'])
def api_admin_weekly_visitors():
    """
    Returns last 7 days labels and visitor counts for charting.
    Response:
      { "success": true, "labels": ["2025-09-16","..."], "data": [5,3,2,...] }
    """
    try:
        # last 7 days including today
        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        cursor.execute("""
            SELECT DATE(entry_time) AS day, COUNT(DISTINCT user_id) AS cnt
            FROM entry_logs
            WHERE entry_time >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
            GROUP BY DATE(entry_time)
            ORDER BY DATE(entry_time) ASC
        """)
        rows = cursor.fetchall()
        cursor.close()

        # build a map day->count
        counts = {r['day'].strftime('%Y-%m-%d'): int(r['cnt']) for r in rows}

        # labels for last 7 days
        labels = []
        data = []
        for i in range(6, -1, -1):  # 6 days ago ... today
            d = (datetime.utcnow().date() - timedelta(days=i)).strftime('%Y-%m-%d')
            labels.append(d)
            data.append(counts.get(d, 0))

        return jsonify({"success": True, "labels": labels, "data": data}), 200

    except Exception as e:
        traceback.print_exc()
        return _json_error(str(e), 500)


# to get all users
@app.route('/api/admin/users', methods=['GET'])
def api_admin_users():
    try:
        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        cursor.execute("SELECT user_id, username, email_id FROM register_details WHERE is_admin = 0")
        users = cursor.fetchall()
        cursor.close()

        return jsonify({
            "success": True,
            "data": users
        }), 200
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500




# ====================== QR ROUTES =========================

@app.route('/api/get_qr', methods=['GET'])
def api_get_qr():
    user_id = request.args.get("user_id")
    if not user_id:
        return _json_error("user_id required", 400)

    try:
        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        cursor.execute("SELECT qr FROM user_detail WHERE user_id = %s", (user_id,))
        record = cursor.fetchone()
        cursor.close()

        if not record or not record.get("qr"):
            return _json_error("QR not found", 404)

        # return PNG bytes
        return send_file(
            io.BytesIO(record["qr"]),
            mimetype="image/png",
            as_attachment=False,
            download_name=f"user_{user_id}_qr.png"
        )

    except Exception as e:
        traceback.print_exc()
        return _json_error(str(e), 500)

#===============================VerifyQR============================
@app.route('/api/verify_qr', methods=['POST'])
def api_verify_qr():
    try:
        data = request.get_json(force=True)
        qr_data = data.get('qr_data')
        log_type = data.get('log_type', 'entry')

        if not qr_data:
            return _json_error("QR data required", 400)

        # attempt to decrypt
        decrypted = fernet.decrypt(qr_data.encode()).decode()
        match = re.search(r"user_id:(\d+)\|auth_token:([\w\-]+)", decrypted)

        if not match:
            return _json_error("Invalid QR format", 400)

        user_id = int(match.group(1))
        auth_token = match.group(2)

        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        cursor.execute("SELECT * FROM user_detail WHERE user_id = %s AND auth_token = %s", (user_id, auth_token))
        user = cursor.fetchone()
        if not user:
            cursor.close()
            return _json_error("User not found", 404)

        cursor.execute("INSERT INTO entry_logs (user_id, log_type) VALUES (%s, %s)", (user_id, log_type))
        mysql.connection.commit()
        cursor.close()

        return jsonify({"success": True, "message": f"{log_type.capitalize()} logged successfully"}), 200

    except Exception as e:
        traceback.print_exc()
        return _json_error(str(e), 500)


# ====================== RUN APP =========================
if __name__ == '__main__':
    # Bind to 0.0.0.0 so Flutter web on other devices can reach it on the LAN.
    app.run(host='0.0.0.0', port=5000, debug=True)

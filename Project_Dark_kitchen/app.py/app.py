from flask import Flask, request, jsonify, session
from mysql.connector import connect, Error
from werkzeug.security import generate_password_hash, check_password_hash
from flask_cors import CORS
import os
import uuid

app = Flask(__name__)
CORS(app)
app.secret_key = os.urandom(24)

# --- КОНФІГУРАЦІЯ БАЗИ ДАНИХ ---
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'Sherenok121',
    'database': 'dark_kitchen_plus'
}


def get_db_connection():
    """Створює та повертає підключення до бази даних."""
    try:
        conn = connect(**DB_CONFIG)
        return conn
    except Error as e:
        print(f"Помилка підключення до MySQL: {e}")
        return None


def get_user_id():
    """Повертає user_id з сесії, або None."""
    return session.get('user_id')


# --- 1. АУТЕНТИФІКАЦІЯ ---

@app.route('/api/register', methods=['POST'])
def register():
    """Реєстрація нового користувача."""
    data = request.form
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')

    if not all([username, email, password]):
        return jsonify({'success': False, 'message': 'Всі поля мають бути заповнені.'}), 400

    conn = get_db_connection()
    if not conn:
        return jsonify({'success': False, 'message': 'Помилка сервера.'}), 500

    cursor = conn.cursor()

    try:
        cursor.execute("SELECT user_id FROM Users WHERE email = %s", (email,))
        if cursor.fetchone():
            return jsonify({'success': False, 'message': 'Користувач з таким Email вже існує.'}), 409

        password_hash = generate_password_hash(password)

        insert_query = "INSERT INTO Users (username, email, password_hash) VALUES (%s, %s, %s)"
        cursor.execute(insert_query, (username, email, password_hash))
        conn.commit()

        user_id = cursor.lastrowid
        session['user_id'] = user_id
        session['user_name'] = username

        return jsonify({
            'success': True,
            'message': f'Реєстрація {username} успішна!',
            'user_name': username
        })

    except Error as e:
        conn.rollback()
        print(f"Помилка БД при реєстрації: {e}")
        return jsonify({'success': False, 'message': 'Помилка сервера при обробці даних.'}), 500

    finally:
        cursor.close()
        conn.close()


@app.route('/api/login', methods=['POST'])
def login():
    """Вхід існуючого користувача."""
    data = request.form
    email = data.get('email')
    password = data.get('password')

    if not all([email, password]):
        return jsonify({'success': False, 'message': 'Введіть Email та пароль.'}), 400

    conn = get_db_connection()
    if not conn:
        return jsonify({'success': False, 'message': 'Помилка сервера.'}), 500

    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("SELECT user_id, username, password_hash FROM Users WHERE email = %s", (email,))
        user = cursor.fetchone()

        if user and check_password_hash(user['password_hash'], password):
            session['user_id'] = user['user_id']
            session['user_name'] = user['username']

            return jsonify({
                'success': True,
                'message': f'Вітаємо, {user["username"]}!',
                'user_name': user['username']
            })
        else:
            return jsonify({'success': False, 'message': 'Невірний Email або пароль.'}), 401

    except Error as e:
        print(f"Помилка БД при вході: {e}")
        return jsonify({'success': False, 'message': 'Помилка сервера.'}), 500

    finally:
        cursor.close()
        conn.close()


@app.route('/api/logout', methods=['POST'])
def logout():
    """Вихід користувача (знищення сесії)."""
    session.pop('user_id', None)
    session.pop('user_name', None)
    return jsonify({'success': True, 'message': 'Вихід успішний.'})


# --- 2. ДОДАВАННЯ КОРИСТУВАЦЬКОГО РЕЦЕПТА (User Story 6) ---

@app.route('/api/add_recipe', methods=['POST'])
def add_recipe():
    """Обробляє форму додавання нового рецепта."""
    user_id = get_user_id()
    if not user_id:
        return jsonify({'success': False, 'message': 'Потрібна авторизація.'}), 401

    data = request.form
    title = data.get('title')
    time = data.get('time')
    category = data.get('category')
    ings_str = data.get('ings')
    steps_str = data.get('steps')

    if not all([title, time, category, ings_str, steps_str]):
        return jsonify({'success': False, 'message': 'Всі поля рецепта мають бути заповнені.'}), 400

    new_recipe_id = 'u' + str(uuid.uuid4()).split('-')[0]
    ingredients_list = [i.strip() for i in ings_str.split(',') if i.strip()]
    steps_list = [s.strip() for s in steps_str.split('\n') if s.strip()]

    default_img = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&q=80'

    conn = get_db_connection()
    if not conn:
        return jsonify({'success': False, 'message': 'Помилка сервера БД.'}), 500

    cursor = conn.cursor()

    try:
        conn.start_transaction()

        # 1. Вставка в таблицю Recipes (ВИПРАВЛЕНО: додано title_ua та title_en)
        recipe_insert = """
        INSERT INTO Recipes (recipe_id, title_ua, title_en, category, time_minutes, difficulty, image_url) 
        VALUES (%s, %s, %s, %s, %s, 'Easy', %s)
        """
        # title використовується двічі (UA і EN)
        cursor.execute(recipe_insert, (new_recipe_id, title, title, category, int(time), default_img))

        # 2. Обробка та вставка Інгредієнтів (ВИПРАВЛЕНО: використовуємо назву як ID)
        for ing_name_ua in ingredients_list:
            ing_id = ing_name_ua.lower()  # ID - назва в нижньому регістрі

            # Перевіряємо, чи існує інгредієнт за його ID (назвою)
            cursor.execute("SELECT ingredient_id FROM Ingredients WHERE ingredient_id = %s", (ing_id,))
            ing_result = cursor.fetchone()

            if not ing_result:
                # Вставляємо, якщо не існує. name_en залишаємо NULL
                ing_insert = "INSERT INTO Ingredients (ingredient_id, name_ua) VALUES (%s, %s)"
                cursor.execute(ing_insert, (ing_id, ing_name_ua))

            # Вставка зв'язку в RecipeIngredients (використовуємо string ID)
            cursor.execute("INSERT INTO RecipeIngredients (recipe_id, ingredient_id) VALUES (%s, %s)",
                           (new_recipe_id, ing_id))

        # 3. Вставка Кроків
        for idx, step_desc in enumerate(steps_list):
            step_insert = """
            INSERT INTO Steps (recipe_id, step_number, description) 
            VALUES (%s, %s, %s)
            """
            cursor.execute(step_insert, (new_recipe_id, idx + 1, step_desc))

        # 4. Додавання тегу 'user'
        cursor.execute("INSERT INTO RecipeDiets (recipe_id, diet_id) VALUES (%s, 'user')",
                       (new_recipe_id,))

        conn.commit()

        return jsonify({'success': True, 'message': 'Рецепт успішно додано!', 'recipe_id': new_recipe_id})

    except Error as e:
        conn.rollback()
        print(f"Помилка БД при додаванні рецепта: {e}")
        return jsonify({'success': False, 'message': 'Помилка сервера при збереженні рецепта.'}), 500

    finally:
        cursor.close()
        conn.close()


# --- ЗАПУСК ---

if __name__ == '__main__':
    app.run(debug=True, port=5000)
DROP DATABASE IF EXISTS `dark_kitchen_plus`;
CREATE DATABASE IF NOT EXISTS `dark_kitchen_plus` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `dark_kitchen_plus`;

-- 1. СТРУКТУРА З БАГАТОМОВНІСТЮ ІНГРЕДІЄНТІВ

CREATE TABLE IF NOT EXISTS `Diets` (
`diet_id` VARCHAR(50) NOT NULL COMMENT 'Diet unique identifier (vegan, student, fast)',
`name_ukr` VARCHAR(50) NOT NULL COMMENT 'Diet name in Ukrainian',
PRIMARY KEY (`diet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='List of dietary restrictions and universal tags';

CREATE TABLE IF NOT EXISTS `Ingredients` (
`ingredient_id` VARCHAR(100) NOT NULL PRIMARY KEY COMMENT 'ID (UA-назва у нижньому регістрі)',
`name_ua` VARCHAR(100) NOT NULL UNIQUE COMMENT 'Назва інгредієнта українською',
`name_en` VARCHAR(100) NULL COMMENT 'Назва інгредієнта англійською'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Список усіх унікальних інгредієнтів з перекладом';

CREATE TABLE IF NOT EXISTS `Recipes` (
`recipe_id` VARCHAR(10) NOT NULL COMMENT 'Унікальний ідентифікатор рецепту (наприклад, r1, r2)',
`title_ua` VARCHAR(255) NOT NULL COMMENT 'Назва страви українською',
`title_en` VARCHAR(255) NOT NULL COMMENT 'Назва страви англійською',
`category` ENUM('breakfast', 'lunch', 'dinner', 'dessert', 'snack') NOT NULL DEFAULT 'dinner' COMMENT 'Категорія прийому їжі',
`time_minutes` INT NOT NULL COMMENT 'Час приготування у хвилинах',
`difficulty` ENUM('Easy', 'Medium', 'Hard', 'Unk') NOT NULL DEFAULT 'Easy' COMMENT 'Складність приготування (змінено на англ. для відповідності JS)',
`calories` INT NULL COMMENT 'Кількість калорій (Ккал)',
`protein_g` INT NULL COMMENT 'Кількість білків у грамах',
`image_url` VARCHAR(255) NULL COMMENT 'URL зображення рецепта',
PRIMARY KEY (`recipe_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Основна інформація про рецепти';

CREATE TABLE IF NOT EXISTS `RecipeDiets` (
`recipe_id` VARCHAR(10) NOT NULL,
`diet_id` VARCHAR(50) NOT NULL,
PRIMARY KEY (`recipe_id`, `diet_id`),
FOREIGN KEY (`recipe_id`) REFERENCES `Recipes`(`recipe_id`) ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (`diet_id`) REFERENCES `Diets`(`diet_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Зв''язок між рецептами та дієтичними обмеженнями/тегами';

CREATE TABLE IF NOT EXISTS `RecipeIngredients` (
`recipe_id` VARCHAR(10) NOT NULL,
`ingredient_id` VARCHAR(100) NOT NULL,
PRIMARY KEY (`recipe_id`, `ingredient_id`),
FOREIGN KEY (`recipe_id`) REFERENCES `Recipes`(`recipe_id`) ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (`ingredient_id`) REFERENCES `Ingredients`(`ingredient_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Зв''язок між рецептами та необхідними інгредієнтами';

CREATE TABLE IF NOT EXISTS `Steps` (
`step_id` INT NOT NULL AUTO_INCREMENT,
`recipe_id` VARCHAR(10) NOT NULL,
`step_number` INT NOT NULL COMMENT 'Порядковий номер кроку',
`description` TEXT NOT NULL COMMENT 'Опис кроку приготування',
PRIMARY KEY (`step_id`),
UNIQUE KEY `recipe_step` (`recipe_id`, `step_number`),
FOREIGN KEY (`recipe_id`) REFERENCES `Recipes`(`recipe_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Покрокова інструкція для рецептів';

-- 2. ТАБЛИЦІ КОРИСТУВАЧІВ (без змін)

CREATE TABLE IF NOT EXISTS `Users` (
`user_id` INT NOT NULL AUTO_INCREMENT,
`username` VARCHAR(100) UNIQUE COMMENT 'Унікальне ім''я користувача',
`email` VARCHAR(255) UNIQUE NOT NULL,
`password_hash` VARCHAR(255) NOT NULL COMMENT 'Хеш пароля для безпеки',
`preferred_cooker` ENUM('gas', 'electric', 'pan', 'pot', 'multi', 'kazan', 'micro', 'none') DEFAULT 'pan' COMMENT 'Обраний прилад для готування',
PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Дані про користувачів та їхні основні налаштування';

CREATE TABLE IF NOT EXISTS `ShoppingList` (
`item_id` INT NOT NULL AUTO_INCREMENT,
`user_id` INT NOT NULL,
`ingredient_name` VARCHAR(100) NOT NULL COMMENT 'Назва інгредієнта',
`is_bought` BOOLEAN DEFAULT FALSE COMMENT 'Відмітка, чи куплено інгредієнт',
PRIMARY KEY (`item_id`),
UNIQUE KEY `user_ingredient` (`user_id`, `ingredient_name`),
FOREIGN KEY (`user_id`) REFERENCES `Users`(`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Список покупок для кожного користувача';

CREATE TABLE IF NOT EXISTS `Favorites` (
`user_id` INT NOT NULL,
`recipe_id` VARCHAR(10) NOT NULL,
PRIMARY KEY (`user_id`, `recipe_id`),
FOREIGN KEY (`user_id`) REFERENCES `Users`(`user_id`) ON DELETE CASCADE,
FOREIGN KEY (`recipe_id`) REFERENCES `Recipes`(`recipe_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Улюблені рецепти користувачів';

CREATE TABLE IF NOT EXISTS `IngredientHistory` (
`history_id` INT NOT NULL AUTO_INCREMENT,
`user_id` INT NOT NULL,
`ingredient_name` VARCHAR(100) NOT NULL,
`added_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (`history_id`),
UNIQUE KEY `user_ingredient_unique` (`user_id`, `ingredient_name`),
FOREIGN KEY (`user_id`) REFERENCES `Users`(`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Історія введених інгредієнтів для кожного користувача';

-- 3. ЗАПОВНЕННЯ СЛОВНИКІВ

INSERT INTO `Diets` (`diet_id`, `name_ukr`) VALUES
('vegan', 'Веган'),
('glutenfree', 'Безглютенове'),
('healthy', 'Здорове (ЗОЖ)'),
('fast', 'Швидке (до 15 хв)'),
('chef', 'Шеф-кухар'),
('party', 'Для вечірки'),
('student', 'Студентське'),
('cheap', 'Економне'),
('spicy', 'Гостре'),
('kazan', 'Казан/Плов'),
('cheatmeal', 'Чітміл'),
('slow', 'Повільне приготування'),
('user', 'Користувацький рецепт'),
('dessert', 'Десерт')
ON DUPLICATE KEY UPDATE `name_ukr`=VALUES(`name_ukr`);


INSERT IGNORE INTO `Ingredients` (`ingredient_id`, `name_ua`, `name_en`) VALUES
('яйця', 'Яйця', 'eggs'),
('масло', 'Масло', 'butter'),
('сіль', 'Сіль', 'salt'),
('хліб', 'Хліб', 'bread'),
('макарони', 'Макарони', 'pasta'),
('кетчуп', 'Кетчуп', 'ketchup'),
('сир', 'Сир', 'cheese'),
('курка', 'Курка', 'chicken'),
('морква', 'Морква', 'carrot'),
('цибуля', 'Цибуля', 'onion'),
('картопля', 'Картопля', 'potato'),
('вода', 'Вода', 'water'),
('мука', 'Мука', 'flour'),
('молоко', 'Молоко', 'milk'),
('цукор', 'Цукор', 'sugar'),
('огірок', 'Огірок', 'cucumber'),
('помідор', 'Помідор', 'tomato'),
('сир фета', 'Сир фета', 'feta cheese'),
('оливки', 'Оливки', 'olives'),
('олія', 'Олія', 'oil'),
('булка', 'Булка', 'bun'),
('фарш', 'Фарш', 'minced meat'),
('салат', 'Салат', 'lettuce'),
('соус', 'Соус', 'sauce'),
('вівсянка', 'Вівсянка', 'oatmeal'),
('ягоди', 'Ягоди', 'berries'),
('мед', 'Мед', 'honey'),
('печиво', 'Печиво', 'cookies'),
('кава', 'Кава', 'coffee'),
('сир маскарпоне', 'Сир маскарпоне', 'mascarpone cheese'),
('рис', 'Рис', 'rice'),
('кукурудза', 'Кукурудза', 'corn'),
('горошок', 'Горошок', 'peas'),
('соєвий соус', 'Соєвий соус', 'soy sauce')
ON DUPLICATE KEY UPDATE `name_en`=VALUES(`name_en`);


-- 4. ЗАПОВНЕННЯ РЕЦЕПТІВ (9 базових рецептів)

INSERT INTO `Recipes` 
(`recipe_id`, `title_ua`, `title_en`, `category`, `time_minutes`, `difficulty`, `image_url`)
VALUES
('r1', 'Студентська Яєчня', 'Student Omelette', 'breakfast', 10, 'Easy', 'https://images.unsplash.com/photo-1525351484163-7529414395d8?w=600&q=80'),
('r2', 'Паста "Кінець місяця"', 'End-of-Month Pasta', 'lunch', 15, 'Easy', 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=600&q=80'),
('r3', 'Курячий Суп', 'Chicken Soup', 'lunch', 45, 'Medium', 'https://images.unsplash.com/photo-1547592180-85f173990554?w=600&q=80'),
('r4', 'Панкейки', 'Pancakes', 'breakfast', 25, 'Medium', 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600&q=80'),
('r5', 'Грецький Салат', 'Greek Salad', 'dinner', 10, 'Easy', 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&q=80'),
('r6', 'Домашній Бургер', 'Homemade Burger', 'dinner', 35, 'Medium', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80'),
('r7', 'Вівсянка з ягодами', 'Oatmeal with Berries', 'breakfast', 5, 'Easy', 'https://api.toastpad.com/img/581453410_1755323103.webp?width=1200&height=660'),
('r8', 'Тірамісу (Ліниве)', 'Lazy Tiramisu', 'dessert', 20, 'Easy', 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=600&q=80'),
('r9', 'Рис з овочами', 'Rice with Vegetables', 'lunch', 25, 'Medium', 'https://smachnonews.24tv.ua/resources/photos/news/202211/2195020.jpg?v=1668020851000')
ON DUPLICATE KEY UPDATE title_ua=VALUES(title_ua), title_en=VALUES(title_en);


-- 5. ЗАПОВНЕННЯ ЗВ'ЯЗКІВ

INSERT INTO `RecipeDiets` (`recipe_id`, `diet_id`) VALUES
('r1', 'student'), ('r1', 'fast'), ('r1', 'cheap'),
('r2', 'student'), ('r2', 'cheap'),
('r3', 'healthy'),
('r4', 'dessert'), ('r4', 'chef'),
('r5', 'healthy'), ('r5', 'vegan'), ('r5', 'glutenfree'), ('r5', 'fast'),
('r6', 'party'), ('r6', 'chef'),
('r7', 'healthy'), ('r7', 'vegan'), ('r7', 'fast'),
('r8', 'dessert'), ('r8', 'party'),
('r9', 'healthy'), ('r9', 'vegan'), ('r9', 'glutenfree')
ON DUPLICATE KEY UPDATE recipe_id=VALUES(recipe_id);


INSERT INTO `RecipeIngredients` (`recipe_id`, `ingredient_id`) VALUES
('r1', 'яйця'), ('r1', 'масло'), ('r1', 'сіль'), ('r1', 'хліб'),
('r2', 'макарони'), ('r2', 'кетчуп'), ('r2', 'сир'),
('r3', 'курка'), ('r3', 'морква'), ('r3', 'цибуля'), ('r3', 'картопля'), ('r3', 'вода'),
('r4', 'мука'), ('r4', 'молоко'), ('r4', 'яйця'), ('r4', 'цукор'), ('r4', 'масло'),
('r5', 'огірок'), ('r5', 'помідор'), ('r5', 'сир фета'), ('r5', 'оливки'), ('r5', 'олія'),
('r6', 'булка'), ('r6', 'фарш'), ('r6', 'сир'), ('r6', 'салат'), ('r6', 'соус'),
('r7', 'вівсянка'), ('r7', 'вода'), ('r7', 'ягоди'), ('r7', 'мед'),
('r8', 'печиво'), ('r8', 'кава'), ('r8', 'сир маскарпоне'), ('r8', 'цукор'),
('r9', 'рис'), ('r9', 'кукурудза'), ('r9', 'горошок'), ('r9', 'морква'), ('r9', 'соєвий соус')
ON DUPLICATE KEY UPDATE recipe_id=VALUES(recipe_id);


INSERT INTO `Steps` (`recipe_id`, `step_number`, `description`) VALUES
('r1', 1, 'Розігрій пательню з маслом.'),
('r1', 2, 'Розбий яйця, посоли.'),
('r1', 3, 'Смаж 5 хв. Їж з хлібом.'),

('r2', 1, 'Звари макарони (10 хв).'),
('r2', 2, 'Злий воду.'),
('r2', 3, 'Залий кетчупом і посип сиром.'),

('r3', 1, 'Звари бульйон з курки.'),
('r3', 2, 'Додай нарізані овочі.'),
('r3', 3, 'Вари до м\'якості.'),

('r4', 1, 'Змішай муку, цукор, яйця і молоко.'),
('r4', 2, 'Смаж на сухій сковороді по 2 хв з кожного боку.'),

('r5', 1, 'Наріж овочі великими кубиками.'),
('r5', 2, 'Додай фету і оливки.'),
('r5', 3, 'Заправ олією та спеціями.'),

('r6', 1, 'Сформуй котлету з фаршу, посмаж.'),
('r6', 2, 'Підігрій булку.'),
('r6', 3, 'Збери: булка, соус, салат, котлета, сир.'),

('r7', 1, 'Залий вівсянку окропом.'),
('r7', 2, 'Дай настоятися 5 хв.'),
('r7', 3, 'Додай ягоди і мед.'),

('r8', 1, 'Завари міцну каву.'),
('r8', 2, 'Збий сир з цукром.'),
('r8', 3, 'Вмочуй печиво в каву і викладай шарами з кремом.'),

('r9', 1, 'Звари рис.'),
('r9', 2, 'Обсмаж овочі на сковороді.'),
('r9', 3, 'Змішай рис з овочами та соусом.')
ON DUPLICATE KEY UPDATE description=VALUES(description);
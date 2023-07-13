1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки»
   
SELECT COUNT(id)
FROM stackoverflow.posts
WHERE post_type_id=1 
   AND (score>300 OR favorites_count >= 100)
GROUP BY post_type_id;

2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.

SELECT ROUND(AVG(questions))
FROM (SELECT p.creation_date::date,COUNT(id) AS questions
      FROM stackoverflow.posts p
      WHERE p.post_type_id = 1 AND p.creation_date::date BETWEEN '2008-11-01' AND '2008-11-18'
      GROUP BY p.creation_date::date) AS t

3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.
   
SELECT COUNT(DISTINCT id)
FROM (SELECT u.id, u.creation_date::date AS reg, b.creation_date::date AS budg
      FROM stackoverflow.users u
      JOIN stackoverflow.badges b ON u.id = b.user_id) AS t
WHERE reg = budg

4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?

SELECT COUNT(DISTINCT p.id)
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON u.id = p.user_id
JOIN stackoverflow.votes v on v.post_id = p.id
WHERE u.display_name = 'Joel Coehoorn'

5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. Таблица должна быть отсортирована по полю id.

SELECT *, ROW_NUMBER() OVER(ORDER BY id DESC) AS rank
FROM stackoverflow.vote_types
ORDER BY id
   
6.Отберите 10 пользователей, которые поставили больше всего голосов типа Close. Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов.
Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.   

SELECT v.user_id, COUNT(v.user_id) AS user_cnt
FROM stackoverflow.votes v
JOIN stackoverflow.vote_types vt ON vt.id = v.vote_type_id
WHERE vt.name = 'Close'
GROUP BY v.user_id
ORDER BY 2 DESC, 1 DESC
LIMIT 10

7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей:
- идентификатор пользователя;
- число значков;
- место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.

SELECT user_id, COUNT(id) AS n_badges, DENSE_RANK() OVER (ORDER BY COUNT(id) DESC)
FROM  stackoverflow.badges
WHERE creation_date::date BETWEEN '2008-11-15' AND '2008-12-15'
GROUP BY user_id
ORDER BY n_badges DESC, user_id
LIMIT 10

8. Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
- заголовок поста;
- идентификатор пользователя;
- число очков поста;
- среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков.

SELECT title, user_id, score, ROUND(avg_score)
FROM (SELECT title, 
             user_id,
             score, 
             AVG(score) OVER (PARTITION BY user_id) AS avg_score
      FROM stackoverflow.posts
      WHERE score <> 0 AND title IS NOT null) AS t

9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. Посты без заголовков не должны попасть в список.

SELECT title
FROM stackoverflow.posts
WHERE title IS NOT null AND user_id IN (SELECT user_id
                                        FROM stackoverflow.badges
                                        GROUP BY user_id
                                        HAVING COUNT(id) > 1000)

10. Напишите запрос, который выгрузит данные о пользователях из США (англ. United States). Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
-пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
- пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
- пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. Пользователи с нулевым количеством просмотров не должны войти в итоговую таблицу.

SELECT id, views,
       CASE 
       WHEN views >= 350 THEN 1
       WHEN views >= 100 AND views < 350 THEN 2
       WHEN views < 100 THEN 3
       END
FROM stackoverflow.users
WHERE location LIKE '%United States%' AND views <> 0

11. Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе.
   Выведите поля с идентификатором пользователя, группой и количеством просмотров. Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.

WITH t AS (
    SELECT id,
           views,
           (CASE 
               WHEN views >= 350 THEN 1
               WHEN views >= 100 AND views < 350 THEN 2
               WHEN views < 100 THEN 3
               END) AS groups
    FROM stackoverflow.users
    WHERE location LIKE '%United States%' AND views <> 0
),

max_scores AS (SELECT *, MAX(views) OVER (PARTITION BY groups) AS max_score
               FROM t
               ORDER BY views DESC)

SELECT id, groups, views
FROM max_scores
WHERE views = max_score
ORDER BY views DESC, id

12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
- номер дня;
- число пользователей, зарегистрированных в этот день;
- сумму пользователей с накоплением.
  
SELECT EXTRACT(DAY FROM creation_date) AS n_day, COUNT(id) as ids_cnt, SUM(COUNT(id)) OVER (ORDER BY EXTRACT(DAY FROM creation_date))
FROM stackoverflow.users
WHERE creation_date::date BETWEEN '2008-11-01' AND '2008-11-30'
GROUP BY n_day
ORDER BY n_day

13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите:
- идентификатор пользователя;
- разницу во времени между регистрацией и первым постом.

WITH t AS (SELECT u.id, 
                  u.creation_date AS reg_date, 
                  p.creation_date AS post_date
           FROM stackoverflow.users u
           JOIN stackoverflow.posts p ON u.id = p.user_id
           ORDER BY id)
SELECT DISTINCT id, (MIN(post_date) OVER (PARTITION BY id)-reg_date) AS delta
FROM t

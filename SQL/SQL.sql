1. Посчитайте, сколько компаний закрылось.

SELECT COUNT(id)
FROM company
WHERE status = 'closed'

2. Отобразите количество привлечённых средств для новостных компаний США. 
   Используйте данные из таблицы company. 
   Отсортируйте таблицу по убыванию значений в поле funding_total .

SELECT funding_total
FROM company
WHERE category_code = 'news' AND country_code = 'USA'
ORDER BY funding_total DESC

3. Найдите общую сумму сделок по покупке одних компаний другими в долларах.
   Отберите сделки, которые осуществлялись только за наличные с 2011 по 2013 год включительно.

SELECT SUM(price_amount)
FROM acquisition
WHERE EXTRACT(YEAR FROM CAST(acquired_at AS date)) IN (2011,2012,2013) AND term_code = 'cash'

4. Отобразите имя, фамилию и названия аккаунтов людей в твиттере, у которых названия аккаунтов начинаются на 'Silver'.

SELECT first_name, last_name, twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%'

5. Выведите на экран всю информацию о людях, у которых названия аккаунтов в твиттере содержат подстроку 'money', а фамилия начинается на 'K'.

SELECT *
FROM people
WHERE twitter_username LIKE '%money%' AND last_name LIKE 'K%'

6. Для каждой страны отобразите общую сумму привлечённых инвестиций, которые получили компании, зарегистрированные в этой стране. 
   Страну, в которой зарегистрирована компания, можно определить по коду страны.
   Отсортируйте данные по убыванию суммы.

SELECT country_code, SUM(funding_total)
FROM company 
GROUP BY country_code
ORDER BY SUM(funding_total) DESC

7. Составьте таблицу, в которую войдёт дата проведения раунда, а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату.
   Оставьте в итоговой таблице только те записи, в которых минимальное значение суммы инвестиций не равно нулю и не равно максимальному значению.

SELECT funded_at, MIN(raised_amount), MAX(raised_amount)
FROM funding_round
GROUP BY funded_at
HAVING MIN(raised_amount) > 0 AND MIN(raised_amount) <> MAX(raised_amount)

8. Создайте поле с категориями:
    Для фондов, которые инвестируют в 100 и более компаний, назначьте категорию high_activity.
    Для фондов, которые инвестируют в 20 и более компаний до 100, назначьте категорию middle_activity.
    Если количество инвестируемых компаний фонда не достигает 20, назначьте категорию low_activity.
  Отобразите все поля таблицы fund и новое поле с категориями.

SELECT *,
    CASE
        WHEN invested_companies >= 100 THEN 'high_activity'
        WHEN invested_companies >= 20 AND invested_companies <100 THEN 'middle_activity'
        WHEN invested_companies < 20 THEN 'low_activity'
        END    
FROM fund

9. Для каждой из категорий, назначенных в предыдущем задании, посчитайте округлённое до ближайшего целого числа среднее количество инвестиционных раундов, 
   в которых фонд принимал участие. Выведите на экран категории и среднее число инвестиционных раундов. Отсортируйте таблицу по возрастанию среднего.

WITH c AS (SELECT *,
    CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity
FROM fund)

SELECT activity, ROUND(AVG(investment_rounds)) AS avg
FROM c
GROUP BY activity
ORDER BY avg      

10. Проанализируйте, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы. 
Для каждой страны посчитайте минимальное, максимальное и среднее число компаний, в которые инвестировали фонды этой страны, основанные с 2010 по 2012 год включительно.
Исключите страны с фондами, у которых минимальное число компаний, получивших инвестиции, равно нулю. 
Выгрузите десять самых активных стран-инвесторов: отсортируйте таблицу по среднему количеству компаний от большего к меньшему. 
Затем добавьте сортировку по коду страны в лексикографическом порядке.

SELECT country_code, 
MIN(invested_companies) AS min,
MAX(invested_companies) AS max,
AVG(invested_companies) AS avg
FROM fund
WHERE EXTRACT(YEAR FROM CAST(founded_at as date)) IN (2010,2011,2012)
GROUP BY country_code
HAVING MIN(invested_companies)!=0
ORDER BY avg DESC, country_code
LIMIT 10

11. Отобразите имя и фамилию всех сотрудников стартапов. Добавьте поле с названием учебного заведения, которое окончил сотрудник, если эта информация известна.

SELECT first_name, last_name, education.instituition
FROM people
LEFT OUTER JOIN education ON education.person_id = people.id

12. Для каждой компании найдите количество учебных заведений, которые окончили её сотрудники. Выведите название компании и число уникальных названий учебных заведений. Составьте топ-5 компаний по количеству университетов.

WITH i AS (SELECT company.name, education.instituition
FROM company
LEFT JOIN people ON people.company_id = company.id
LEFT JOIN education ON people.id = education.person_id
WHERE people.company_id IS NOT NULL AND
      education.instituition IS NOT NULL)

SELECT i.name, COUNT(DISTINCT(i.instituition))
FROM i
GROUP BY i.name
ORDER BY count DESC
LIMIT 5

13. Составьте список с уникальными названиями закрытых компаний, для которых первый раунд финансирования оказался последним.
      
WITH c AS (SELECT name, id
           FROM company
           WHERE status = 'closed'),
     f AS (SELECT company_id
           FROM funding_round
           WHERE is_first_round = 1 AND
                 is_last_round = 1)
SELECT DISTINCT(c.name)
FROM c INNER JOIN f ON f.company_id = c.id 


14. Составьте список уникальных номеров сотрудников, которые работают в компаниях, отобранных в предыдущем задании.
      
WITH c AS (SELECT name, id
           FROM company
           WHERE status = 'closed'),
     f AS (SELECT company_id
           FROM funding_round
           WHERE is_first_round = 1 AND
                 is_last_round = 1)

SELECT people.id
FROM people
WHERE people.company_id IN (SELECT DISTINCT(c.id)
                            FROM c INNER JOIN f ON f.company_id = c.id)
      

15. Составьте таблицу, куда войдут уникальные пары с номерами сотрудников из предыдущей задачи и учебным заведением, которое окончил сотрудник.

WITH c AS (SELECT name, id
           FROM company
           WHERE status = 'closed'),
     f AS (SELECT company_id
           FROM funding_round
           WHERE is_first_round = 1 AND
                 is_last_round = 1)


SELECT people.id, education.instituition
      FROM people
      INNER JOIN education ON people.id = education.person_id
      WHERE people.company_id IN (SELECT DISTINCT(c.id)
                                  FROM c INNER JOIN f ON f.company_id = c.id)
GROUP BY people.id, education.instituition
      

16. Посчитайте количество учебных заведений для каждого сотрудника из предыдущего задания. При подсчёте учитывайте, что некоторые сотрудники могли окончить одно и то же заведение дважды.
      
WITH c AS (SELECT name, id
           FROM company
           WHERE status = 'closed'),
     f AS (SELECT company_id
           FROM funding_round
           WHERE is_first_round = 1 AND
                 is_last_round = 1)


SELECT people.id, COUNT(education.instituition)
FROM people
INNER JOIN education ON people.id = education.person_id
WHERE people.company_id IN (SELECT DISTINCT(c.id)
                            FROM c INNER JOIN f ON f.company_id = c.id)
GROUP BY people.id

17. Дополните предыдущий запрос и выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники разных компаний.

WITH c AS (SELECT name, id
           FROM company
           WHERE status = 'closed'),
     f AS (SELECT company_id
           FROM funding_round
           WHERE is_first_round = 1 AND
                 is_last_round = 1)

SELECT AVG(count)
FROM (SELECT people.id, COUNT(education.instituition)
      FROM people
      INNER JOIN education ON people.id = education.person_id
      WHERE people.company_id IN (SELECT DISTINCT(c.id)
                                FROM c INNER JOIN f ON f.company_id = c.id)
      GROUP BY people.id) AS z2

18. Напишите похожий запрос: выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники Facebook*.
*(сервис, запрещённый на территории РФ)

WITH q AS (SELECT person_id, COUNT(instituition)
FROM education
WHERE person_id IN (SELECT id
                    FROM people
                    WHERE company_id IN (SELECT id
                                         FROM company
                                         WHERE name = 'Facebook'))
GROUP BY person_id)

SELECT AVG(count)
FROM q

19. Составьте таблицу из полей:
- name_of_fund — название фонда;
- name_of_company — название компании;
- amount — сумма инвестиций, которую привлекла компания в раунде.
В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, а раунды финансирования проходили с 2012 по 2013 год включительно.

SELECT f.name AS name_of_fund, 
       C.name AS name_of_company, 
       fr.raised_amount AS amount
FROM investment AS i
JOIN company AS c ON i.company_id=c.id
JOIN fund AS f ON i.fund_id=f.id
JOIN funding_round AS fr ON i.funding_round_id = fr.id
WHERE EXTRACT(YEAR FROM fr.funded_at) BETWEEN 2012 AND 2013
   AND c.milestones > 6;

20. Выгрузите таблицу, в которой будут такие поля:
- название компании-покупателя;
- сумма сделки;
- название компании, которую купили;
- сумма инвестиций, вложенных в купленную компанию;
- доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций, округлённая до ближайшего целого числа.
Не учитывайте те сделки, в которых сумма покупки равна нулю. Если сумма инвестиций в компанию равна нулю, исключите такую компанию из таблицы. 
Отсортируйте таблицу по сумме сделки от большей к меньшей, а затем по названию купленной компании в лексикографическом порядке. Ограничьте таблицу первыми десятью записями.

-- первичная таблица с 3 нужными полями и первым фильтром ненулевой сделки
WITH q1 AS (
                SELECT acquiring_company_id,
                       acquired_company_id,
                       price_amount
                FROM acquisition
                WHERE price_amount > 0
               )
               
SELECT company.name AS acquiring_company,
       q2.price_amount,
       q2.acquired_company,
       q2.funding_total,
       ROUND(q2.price_amount / q2.funding_total)

-- добавляем название компании, которую купили и нужный столбец с суммой вложенных инвестиций
FROM 
(
    SELECT c.name AS acquired_company,
           c.funding_total,
           q1.acquiring_company_id,
           q1.price_amount
    FROM company AS c
    RIGHT JOIN q1 ON c.id = q1.acquired_company_id
 ) AS q2 LEFT JOIN company ON company.id  = q2.acquiring_company_id
WHERE q2.funding_total > 0
ORDER BY  q2.price_amount DESC, q2.acquired_company
LIMIT 10;

21. Выгрузите таблицу, в которую войдут названия компаний из категории social, получившие финансирование с 2010 по 2013 год включительно.
    Проверьте, что сумма инвестиций не равна нулю. 
    Выведите также номер месяца, в котором проходил раунд финансирования.

FROM company AS c
RIGHT JOIN (
             SELECT company_id,
                     EXTRACT(MONTH FROM funded_at) AS month
             FROM funding_round
             WHERE EXTRACT(YEAR FROM funded_at) BETWEEN 2010 AND 2013
                   AND raised_amount != 0
            ) AS tab1 ON c.id = tab1.company_id
WHERE c.category_code LIKE 'social';

22. Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды. Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля:
- номер месяца, в котором проходили раунды;
- количество уникальных названий фондов из США, которые инвестировали в этом месяце;
- количество компаний, купленных за этот месяц;
- общая сумма сделок по покупкам в этом месяце.

WITH 
fonds AS (
    SELECT month, COUNT(DISTINCT(name)) AS fond
    FROM (SELECT EXTRACT(MONTH FROM funded_at) AS month, f.name, f.country_code
          FROM funding_round AS fr
          LEFT JOIN investment AS i ON i.funding_round_id = fr.id
          LEFT JOIN fund AS f ON  i.fund_id = f.id
          WHERE EXTRACT(YEAR FROM funded_at) BETWEEN 2010 AND 2013
                AND f.country_code = 'USA'
                ) AS fonds
                GROUP BY month       
),

comp AS (SELECT month, COUNT(acquired_company_id) AS companies, SUM(price_amount) AS deals
         FROM (SELECT EXTRACT(MONTH FROM acquired_at) AS month, acquired_company_id, price_amount
               FROM acquisition
               WHERE EXTRACT(YEAR FROM acquired_at) BETWEEN 2010 AND 2013) AS comps
               GROUP BY month)

SELECT fonds.month, fonds.fond, comp.companies, comp.deals
FROM fonds
LEFT JOIN comp ON comp.month = fonds.month 

23. Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран, в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах.
    Данные за каждый год должны быть в отдельном поле. Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему.

WITH 
y_2011 AS ( 
    SELECT country_code, AVG(funding_total) AS avg_2011
    FROM company 
    WHERE EXTRACT(YEAR FROM founded_at) = 2011
    GROUP BY country_code),

y_2012 AS ( 
    SELECT country_code, AVG(funding_total) AS avg_2012
    FROM company 
    WHERE EXTRACT(YEAR FROM founded_at) = 2012
    GROUP BY country_code),
 y_2013 AS ( 
    SELECT country_code, AVG(funding_total) AS avg_2013
    FROM company 
    WHERE EXTRACT(YEAR FROM founded_at) = 2013
    GROUP BY country_code)
    
SELECT y_2011.country_code, y_2011.avg_2011, y_2012.avg_2012, y_2013.avg_2013
FROM y_2011
INNER JOIN y_2012 ON y_2011.country_code =  y_2012.country_code
INNER JOIN y_2013 ON y_2011.country_code =  y_2013.country_code
ORDER BY y_2011.avg_2011 DESC

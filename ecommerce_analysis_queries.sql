-- ========================================================
-- PROYECTO: Análisis de Transacciones de E-commerce
-- ARCHIVO: 01_creation
-- DESCRIPCIÓN: Creación de la estructura de la tabla
-- ========================================================

-- 1. Crear la tabla con tipos de datos óptimos para finanzas
CREATE TABLE ecommerce_transactions (
    user_id VARCHAR(50),
    product_id VARCHAR(50),
    category VARCHAR(100),
    price NUMERIC(10, 2),
    discount NUMERIC(5, 2),
    final_price NUMERIC(10, 2),
    payment_method VARCHAR(50),
    purchase_date VARCHAR(20)
);
-- Nota de desarrollo: Script de reinicio en caso de cambios en el CSV
--DROP TABLE ecommerce_transactions;

-- 2. Verificar que los datos se importaron correctamente
SELECT
	*
FROM
	ecommerce_transactions
LIMIT 10;

-- ========================================================
-- PROYECTO: Análisis de Transacciones de E-commerce
-- ARCHIVO: 02_cleaning
-- DESCRIPCIÓN: Limpieza y transformación de datos (Data Cleaning)
-- ========================================================

-- 1. Verificar si existen filas completamente duplicadas
SELECT
	user_id,
	product_id,
	purchase_date,
	COUNT(*) AS cantidad_repetidos
FROM
	ecommerce_transactions
GROUP BY
	user_id,
	product_id,
	purchase_date
HAVING
	COUNT(*) > 1;


-- 2. Estandarizar el formato del texto de la fecha a YYYY-MM-DD
UPDATE ecommerce_transactions
SET purchase_date = TO_DATE(purchase_date, 'DD-MM-YYYY')::VARCHAR;

ALTER TABLE ecommerce_transactions
ALTER COLUMN purchase_date TYPE DATE USING purchase_date::DATE;


-- 3. Contar valores nulos por cada columna
SELECT 
    COUNT(*) FILTER (WHERE user_id IS NULL) AS nulos_user,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS nulos_product,
    COUNT(*) FILTER (WHERE category IS NULL) AS nulos_category,
    COUNT(*) FILTER (WHERE price IS NULL) AS nulos_price,
    COUNT(*) FILTER (WHERE payment_method IS NULL) AS nulos_payment
FROM ecommerce_transactions;


-- 4. Agregar las nuevas columnas utiles vacías a la tabla
ALTER TABLE ecommerce_transactions 
ADD COLUMN purchase_month VARCHAR(20),
ADD COLUMN day_of_week VARCHAR(20);

UPDATE ecommerce_transactions
SET 
    purchase_month = TO_CHAR(purchase_date, 'Month'),
    day_of_week = TO_CHAR(purchase_date, 'Day');

SELECT
	*
FROM
	ecommerce_transactions
LIMIT 5;


-- ========================================================
-- PROYECTO: Análisis de Transacciones de E-commerce
-- ARCHIVO: 03_analysis
-- DESCRIPCIÓN: Análisis Exploratorio y Métricas de Negocio (EDA)
-- ========================================================


-- KPIs principales
SELECT
	SUM(final_price) AS ingresos_totales,
	ROUND(AVG(discount), 2) AS descuento_promedio_porcentaje,
	ROUND(AVG(final_price), 2) AS ticket_promedio_compra
FROM
	ecommerce_transactions;


-- Categorias estrella
SELECT 
    category,
    COUNT(*) AS cantidad_ventas,
    SUM(final_price) AS ingresos_por_categoria
FROM ecommerce_transactions
GROUP BY category
ORDER BY ingresos_por_categoria DESC;


-- Metodos de pago preferidos
SELECT 
    payment_method,
    COUNT(*) AS total_transacciones,
    ROUND((COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM ecommerce_transactions) * 100), 2) AS porcentaje_preferencia
FROM ecommerce_transactions
GROUP BY payment_method
ORDER BY total_transacciones DESC;


-- Ventas por dia de la semana
SELECT 
    day_of_week,
    COUNT(*) AS total_ventas,
    SUM(final_price) AS ingresos_totales
FROM ecommerce_transactions
GROUP BY day_of_week
ORDER BY ingresos_totales DESC;


-- Ventas por mes
SELECT 
    purchase_month,
    COUNT(*) AS total_ventas,
    SUM(final_price) AS ingresos_totales
FROM ecommerce_transactions
GROUP BY purchase_month
ORDER BY ingresos_totales DESC;


-- Categoria estrella por dia de la semana
WITH ranking_ventas AS (
    SELECT 
        day_of_week,
        category,
        SUM(final_price) AS ingresos,
        RANK() OVER (PARTITION BY day_of_week ORDER BY SUM(final_price) DESC) AS puesto
    FROM ecommerce_transactions
    GROUP BY day_of_week, category
)
SELECT 
    day_of_week,
    category,
    ingresos
FROM ranking_ventas
WHERE puesto = 1;

SELECT * FROM ecommerce_transactions;
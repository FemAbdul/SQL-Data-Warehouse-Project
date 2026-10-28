SELECT TOP (1000) [sls_ord_num]
      ,[sls_prd_key]
      ,[sls_cust_id]
      ,[sls_order_dt]
      ,[sls_ship_dt]
      ,[sls_due_dt]
      ,[sls_sales]
      ,[sls_quantity]
      ,[sls_price]
  FROM [DataWarehouse].[Bronze].[crm_sales_details]


  SELECT sls_ord_num
  FROM Bronze.crm_sales_details
  WHERE sls_ord_num != TRIM(sls_ord_num);

  --Check the integrity of prd_key and cst_id

  SELECT sls_prd_key
  FROM Bronze.crm_sales_details
  WHERE sls_prd_key NOT IN (SELECT prd_key FROM Silver.crm_prd_info);

  SELECT sls_cust_id
  FROM Bronze.crm_sales_details
  WHERE sls_cust_id NOT IN (SELECT cst_id FROM Bronze.crm_cst_info);

--Check for Invalid Dates
--Date is an integer
---------------------------------------------------
 SELECT sls_order_dt
 FROM Bronze.crm_sales_details
 WHERE sls_order_dt <= 0;

 SELECT NULLIF(sls_order_dt,0)
 FROM Bronze.crm_sales_details
 WHERE sls_order_dt <= 0;

 SELECT sls_order_dt
 FROM Bronze.crm_sales_details
 WHERE sls_order_dt <= 0 OR LEN(sls_order_dt) !=8;

 SELECT sls_ship_dt
 FROM Bronze.crm_sales_details
 WHERE sls_ship_dt <= 0 OR LEN(sls_ship_dt) !=8;

 SELECT sls_due_dt
 FROM Bronze.crm_sales_details
 WHERE sls_due_dt <= 0 OR LEN(sls_due_dt) !=8;

  SELECT sls_order_dt
 FROM Bronze.crm_sales_details
 WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;
 ---------------------------------------------------
 SELECT sls_ord_num,
      sls_prd_key,
      sls_cust_id,
      CASE WHEN sls_order_dt <= 0 OR  LEN(sls_order_dt) !=8 THEN NULL
      ELSE CAST(CAST(sls_order_dt AS varchar) AS date)
      END AS sls_order_dt
      ,CASE WHEN sls_ship_dt <= 0 OR  LEN(sls_ship_dt) !=8 THEN NULL
      ELSE CAST(CAST(sls_ship_dt AS varchar) AS date)
      END AS sls_ship_dt
      ,CASE WHEN sls_due_dt <= 0 OR  LEN(sls_due_dt) !=8 THEN NULL
      ELSE CAST(CAST(sls_due_dt AS varchar) AS date)
      END AS sls_due_dt
      ,[sls_sales]
      ,[sls_quantity]
      ,[sls_price]
  FROM [DataWarehouse].[Bronze].[crm_sales_details]
---------------------------------------------------
  --Sales,Quantity and Price
        --Check for Negatives, Zeros, Nulls
        --SALES = QUANTITY * PRICE
---------------------------------------------------
  SELECT sls_ord_num,sls_sales,sls_quantity, sls_price
  FROM Bronze.crm_sales_details
  WHERE sls_sales <= 0 OR sls_sales IS NULL 
        OR sls_quantity <=0 OR  sls_quantity IS NULL
        OR sls_price <= 0 OR sls_price IS NULL
        OR sls_sales != (sls_quantity * sls_price)
  ORDER BY sls_sales,sls_quantity, sls_price;

---------------------------------------------------
   SELECT sls_ord_num,
      sls_prd_key,
      sls_cust_id,
      CASE WHEN sls_order_dt <= 0 OR  LEN(sls_order_dt) !=8 THEN NULL
      ELSE CAST(CAST(sls_order_dt AS varchar) AS date)
      END AS sls_order_dt
      ,CASE WHEN sls_ship_dt <= 0 OR  LEN(sls_ship_dt) !=8 THEN NULL
      ELSE CAST(CAST(sls_ship_dt AS varchar) AS date)
      END AS sls_ship_dt
      ,CASE WHEN sls_due_dt <= 0 OR  LEN(sls_due_dt) !=8 THEN NULL
      ELSE CAST(CAST(sls_due_dt AS varchar) AS date)
      END AS sls_due_dt,
      CASE WHEN sls_sales <= 0 
                OR sls_sales IS NULL
                OR sls_sales != (sls_quantity * ABS(sls_price))
                THEN sls_quantity * ABS(sls_price)
      ELSE sls_sales
      END AS sls_sales,
      sls_quantity,
      CASE WHEN sls_price <=0 OR sls_price IS NULL THEN sls_sales / NULLIF(sls_quantity,0)
           ELSE sls_price
      END AS sls_price
  FROM [DataWarehouse].[Bronze].[crm_sales_details]
---------------------------------------------------
--CHANGE DDL BEFORE INSERTING VALUES 
---------------------------------------------------
--INSERT DATA TO SILVER LAYER
---------------------------------------------------
INSERT INTO Silver.crm_sales_details(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
 SELECT sls_ord_num,
      sls_prd_key,
      sls_cust_id,
      CASE WHEN sls_order_dt <= 0 OR  LEN(sls_order_dt) !=8 THEN NULL
      ELSE CAST(CAST(sls_order_dt AS varchar) AS date)
      END AS sls_order_dt
      ,CASE WHEN sls_ship_dt <= 0 OR  LEN(sls_ship_dt) !=8 THEN NULL
      ELSE CAST(CAST(sls_ship_dt AS varchar) AS date)
      END AS sls_ship_dt
      ,CASE WHEN sls_due_dt <= 0 OR  LEN(sls_due_dt) !=8 THEN NULL
      ELSE CAST(CAST(sls_due_dt AS varchar) AS date)
      END AS sls_due_dt,
      CASE WHEN sls_sales <= 0 
                OR sls_sales IS NULL
                OR sls_sales != (sls_quantity * ABS(sls_price))
                THEN sls_quantity * ABS(sls_price)
      ELSE sls_sales
      END AS sls_sales,
      sls_quantity,
      CASE WHEN sls_price <=0 OR sls_price IS NULL THEN sls_sales / NULLIF(sls_quantity,0)
           ELSE sls_price
      END AS sls_price
  FROM Bronze.crm_sales_details
---------------------------------------------------
--DATA QUALITY CHECK
---------------------------------------------------
 SELECT sls_order_dt
 FROM Silver.crm_sales_details
 WHERE sls_order_dt <= 0;

   SELECT sls_order_dt
 FROM Bronze.crm_sales_details
 WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

   SELECT sls_ord_num,sls_sales,sls_quantity, sls_price
  FROM Silver.crm_sales_details
  WHERE sls_sales <= 0 OR sls_sales IS NULL 
        OR sls_quantity <=0 OR  sls_quantity IS NULL
        OR sls_price <= 0 OR sls_price IS NULL
        OR sls_sales != (sls_quantity * sls_price)
  ORDER BY sls_sales,sls_quantity, sls_price;

  

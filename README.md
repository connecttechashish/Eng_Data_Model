# **Vayu Air – Data Warehouse Build**

This repository contains my full solution for the Vayu Air data‑warehouse assignment. The goal was to take raw airline operational data and shape it into a clean, well‑structured warehouse: a star schema, SCD Type 2 dimensions, snowflaked geography, and a partitioned fact table. Everything is built in SQL Server (T‑SQL).

It’s essentially a mini real‑world analytics engineering project — raw feeds coming in, conformed dimensions, a scalable fact table, and a curated gold layer ready for BI.

---

## ** Repository Structure**

```
/sql
    01_grain_and_classification.sql
    02_star_schema_ddl.sql
    03_dimension_and_fact_load.sql
    04_snowflake_geography.sql
    05_scd_type2_passenger.sql
    06_partitioning_fact_sales.sql
    07_medallion_and_data_contract.sql

/screenshots
    partition_pruned.png
    partition_not_pruned.png

README.md
```

Each script corresponds to one assignment task and can be run in order.

---

## ** Project Breakdown**

### **1. Grain & Column Classification**
I started by defining the grain of the sales fact:

**One row = one ticket booking (one passenger, one flight).**

From there:
- Dimension keys → who/what/where/when  
- Measures → anything numeric that you’d SUM  
- Additive vs non‑additive measures explained  

This step sets the foundation for the entire model.

---

### **2. Star Schema**
The warehouse lives in a `dw` schema and includes:

- **FactTicketSales**  
- **DimDate**  
- **DimPassenger**  
- **DimFlight**  
- **DimAirport**  
- **DimAircraft**

Dimensions use surrogate keys and retain their business keys.  
The fact table references them with foreign keys and stores only additive measures.

---

### **3. Loading Dimensions & Fact**
I built a proper **DimDate** (with a `yyyymmdd` key), loaded all dimensions from the bronze tables, and populated the fact by joining bronze_bookings to each dimension on its business key.

Verification checks:
- Fact row count matches bronze_bookings  
- No NULL foreign keys  

Once those pass, the star schema is wired correctly.

---

### **4. Snowflaked Geography**
The raw airport table mixes airport, city, and country. I normalized it into:

- **DimCountry**  
- **DimCity**  
- **DimAirportSnowflake**

This reduces repetition (e.g., “India” appearing hundreds of times) and improves data quality.  
The trade‑off: more joins — classic snowflake vs star decision.

---

### **5. Passenger SCD Type 2**
Passenger tier and home airport can change over time, so I rebuilt the passenger dimension using the Type 2 pattern.

Two‑step load:
1. **MERGE** to expire old versions and insert brand‑new passengers  
2. **INSERT** new current versions for passengers whose attributes changed  

The result: passengers who changed have two versions with correct effective dates.

---

### **6. Partitioning the Fact Table**
The sales fact is the largest table, so I partitioned it by `BookingDateKey` using monthly boundaries.

Two queries demonstrate how SQL Server handles partition pruning:

- Filtering **on the partition key** → only a few partitions scanned  
- Filtering **on a non‑partition column** → all partitions scanned  

---

### **7. Medallion Architecture & Data Contract**

#### **Medallion Mapping**
| Table | Layer | Reason |
|-------|--------|--------|
| bronze_* | Bronze | Raw landed source data |
| dw.Dim* | Silver | Cleaned, conformed dimensions (including SCD2) |
| dw.FactTicketSales | Gold | Analytics‑ready, partitioned star schema |

#### **Data Contract for `bronze_bookings`**
Includes:
- Schema & data types  
- Allowed values for `fare_class` and `booking_status`  
- Freshness SLA (daily by 03:00)  
- Ownership (Revenue & Analytics team)  
- Breaking vs non‑breaking change examples  

---

## ** How to Run**
1. Load the bronze tables first.  
2. Run the SQL scripts in order (`01 → 07`).  
3. Turn on **Actual Execution Plan** in SSMS for the partitioning task.

---

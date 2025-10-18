# PostgreSQL Bronze Layer CSV Load on macOS

## Project Context
This project involves loading CSV files into the `bronze` schema of a PostgreSQL data warehouse. The CSVs come from two sources: CRM and ERP. During development on macOS, several issues were encountered with file permissions, server-side COPY, and shell behavior. This document summarizes the problems and solutions.

---

## Folder Structure

**Original files on Desktop:**
```bash
~/Desktop/Learning/sql-data-warehouse-project/datasets/
├── source_crm/
│   ├── cust_info.csv
│   ├── prd_info.csv
│   └── sales_details.csv
└── source_erp/
├── loc_a101.csv
├── cust_az12.csv
└── px_cat_g1v2.csv

**Server-accessible folder used for COPY (optional):**

/tmp/postgres_csvs/
├── source_crm/
├── source_erp/
```
---
---

## Issues Encountered

1. **Moving datasets to PostgreSQL server folder**
   - Error: `mv ... /usr/local/var/postgres/: No such file or directory`
   - Cause: Destination folder did not exist.

2. **Setting ownership and permissions on /tmp/postgres_csvs**
   - Error: 
     ```
     chown: /tmp/postgres_csvs: No such file or directory
     zsh: no matches found: /tmp/postgres_csvs/*.csv
     ```
   - Cause: Folder did not exist and zsh treats unmatched wildcards as errors.

3. **Permission denied when listing CSV files**
   - Error: `ls /tmp/postgres_csvs/source_crm: Permission denied`
   - Cause: `_postgres` user owned the folder, and regular user had no execute/read permissions.

4. **COPY server-side errors**
   - Error: `ERROR: could not open file ... Permission denied`
   - Cause: PostgreSQL server cannot access files in user directories.

5. **zsh wildcard errors**
   - Error: `zsh: no matches found: /Users/.../*.csv`
   - Cause: zsh strict globbing policy for unmatched wildcards.


---

## Solutions Applied

1. **Create missing folders**
```bash
sudo mkdir -p /usr/local/var/postgres/datasets
sudo mkdir -p /tmp/postgres_csvs
```
2.**Copy CSVs to server-accessible folder**
```bash
sudo cp -R /usr/local/var/postgres/datasets/* /tmp/postgres_csvs/
```
**3.	Set ownership to PostgreSQL server user**
```bash
sudo chown -R _postgres:_postgres /tmp/postgres_csvs
```
**4.	Set folder and file permissions**
```bash
sudo chmod -R 755 /tmp/postgres_csvs
sudo find /tmp/postgres_csvs -type f -name "*.csv" -exec chmod 644 {} \;
```
**5.	Disable strict wildcard errors in zsh**
```bash
setopt +o nomatch
```
**6.	Verify files**
```
ls /tmp/postgres_csvs/source_crm
# Expected output:
# cust_info.csv  prd_info.csv  sales_details.csv
```
----

**Lessons Learned**
- Server-side COPY vs client-side \COPY
- COPY → server reads file; requires server user permissions.
- \COPY → client reads file; avoids server permission issues.
 
**Recommended for local development on macOS.**
- Permissions
- Directories require x permission to be entered.
- Files need r permission for server user to read.
- zsh Wildcards
- Unmatched wildcards throw errors in zsh; use setopt +o nomatch or quote paths.

----

Recommended Workflow for Local Development
1. Keep CSVs in your Desktop or Home folder.
2. Use \COPY in psql instead of server-side COPY. 
- Example:
```sql
\COPY bronze.crm_cust_info(cst_id, cst_key, cst_firstname, cst_lastname,cst_marital_status,cst_gndr, cst_create_date)
FROM '~/Desktop/Learning/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
DELIMITER ',' CSV HEADER;
```
3. Repeat for other tables (crm_prd_info, crm_sales_details, erp_loc_a101, etc.).
4. Optionally, create a .sql script to run all \COPY commands sequentially.
----

**Optional: Server-side COPY**

If you prefer server-side COPY:
1. Copy CSVs to a folder readable by PostgreSQL server (e.g., /tmp/postgres_csvs).
2. Ensure _postgres owns the folder and files:
 ```
 sudo chown -R _postgres:_postgres /tmp/postgres_csvs
 sudo find /tmp/postgres_csvs -type f -name "*.csv" -exec chmod 644 {} \;
 ```
3. Update COPY commands to use /tmp/postgres_csvs/... paths.

-----

References
- PostgreSQL COPY vs \COPY documentation: PostgreSQL COPY
- macOS file permissions for PostgreSQL: PostgreSQL on macOS
- zsh globbing options: setopt manual (man zshoptions)

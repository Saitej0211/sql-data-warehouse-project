# PostgreSQL Bronze Layer CSV Load on macOS

## Project Context

This project involves loading **CSV files** into the `bronze` schema of a **PostgreSQL** data warehouse. The CSVs come from two sources: **CRM** and **ERP**. During development on macOS, several issues were encountered with file permissions, server-side `COPY`, and shell behavior. This document summarizes the problems and solutions.

---

## Folder Structure

**Original files on Desktop:**

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
└── source_erp/

---

## Issues Encountered

### Moving datasets to PostgreSQL server folder
* **Error:** mv ... /usr/local/var/postgres/: No such file or directory
* **Cause:** Destination folder did not exist.

### Setting ownership and permissions on /tmp/postgres_csvs
* **Error:** chown: /tmp/postgres_csvs: No such file or directory
* **Error:** zsh: no matches found: /tmp/postgres_csvs/*.csv
* **Cause:** Folder did not exist and **zsh** treats unmatched wildcards as errors.

### Permission denied when listing CSV files
* **Error:** ls /tmp/postgres_csvs/source_crm: Permission denied
* **Cause:** `_postgres` user owned the folder, and the regular user had no execute/read permissions.

### COPY server-side errors
* **Error:** ERROR: could not open file ... Permission denied
* **Cause:** PostgreSQL server cannot access files in user directories, or the server user (`_postgres`) doesn't have the necessary read permissions.

### zsh wildcard errors
* **Error:** zsh: no matches found: /Users/.../*.csv
* **Cause:** **zsh** strict globbing policy for unmatched wildcards.

---

## Solutions Applied

1. **Create missing folders**
    sudo mkdir -p /usr/local/var/postgres/datasets
    sudo mkdir -p /tmp/postgres_csvs

2. **Copy CSVs to server-accessible folder**
    sudo cp -R /usr/local/var/postgres/datasets/* /tmp/postgres_csvs/

3. **Set ownership to PostgreSQL server user**
    sudo chown -R _postgres:_postgres /tmp/postgres_csvs

4. **Set folder and file permissions**
    # Set directories to 755 (rwx for owner, rx for group/others)
    sudo chmod -R 755 /tmp/postgres_csvs
    # Set files to 644 (rw for owner, r for group/others)
    sudo find /tmp/postgres_csvs -type f -name "*.csv" -exec chmod 644 {} ;

5. **Disable strict wildcard errors in zsh**
    setopt +o nomatch

6. **Verify files**
    ls /tmp/postgres_csvs/source_crm
    # Expected output:
    # cust_info.csv prd_info.csv sales_details.csv

---

## Lessons Learned

| Feature | COPY (Server-side) | \COPY (Client-side) |
| :--- | :--- | :--- |
| **Execution Context** | PostgreSQL Server | **psql** Client |
| **File Access** | Server reads file. | Client reads file. |
| **Permissions** | Requires **server user** (`_postgres`) permissions. | Avoids server permission issues. |
| **Recommendation** | For production/staging environments. | **Recommended for local development on macOS.** |

* **Permissions:** Directories require **`x`** (execute) permission to be entered. Files need **`r`** (read) permission for the server user to read.
* **zsh Wildcards:** Unmatched wildcards throw errors in `zsh`; use `setopt +o nomatch` or quote paths to avoid this.

---

## Recommended Workflow for Local Development

The most straightforward approach on macOS is to use the client-side `\COPY` command.

1. Keep CSVs in your Desktop or Home folder.
2. Use `\COPY` in `psql` instead of server-side `COPY`.

**Example:**
\COPY bronze.crm_cust_info(cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
FROM '~/Desktop/Learning/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
DELIMITER ',' CSV HEADER;

3. Repeat this process for other tables (e.g., `crm_prd_info`, `crm_sales_details`, `erp_loc_a101`).
4. Optionally, create a `.sql` script to run all `\COPY` commands sequentially.

-----

## Optional: Server-side COPY

If server-side `COPY` is preferred or required:

1. Copy CSVs to a folder readable by PostgreSQL server (e.g., `/tmp/postgres_csvs`).
2. Ensure `_postgres` owns the folder and files and has read access:
    sudo chown -R _postgres:_postgres /tmp/postgres_csvs
    sudo find /tmp/postgres_csvs -type f -name "*.csv" -exec chmod 644 {} ;

3. Update `COPY` commands to use the server-accessible paths:
    COPY bronze.crm_cust_info(...)
    FROM '/tmp/postgres_csvs/source_crm/cust_info.csv'
    DELIMITER ',' CSV HEADER;

-----

## References

* **PostgreSQL `COPY` vs `\COPY` documentation:** [PostgreSQL COPY](https://www.postgresql.org/docs/current/sql-copy.html)
* **macOS file permissions for PostgreSQL:** [PostgreSQL on macOS](https://www.google.com/search?q=https://wiki.postgresql.org/wiki/Running_PostgreSQL_On_a_Mac_OS_X_Server)
* **zsh globbing options:** [setopt manual (man zshoptions)](https://zsh.sourceforge.io/Doc/Release/Options.html)

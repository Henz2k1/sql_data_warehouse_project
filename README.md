# Data Warehouse and Analytics Project

Welcome to the **Data Warehouse and Analytics Project** repository! 🚀  
This project showcases a complete data warehousing and analytics solution — from raw data ingestion to actionable business insights. Designed as a portfolio project, it follows industry best practices in data engineering, modeling, and reporting.

---

## 📖 Table of Contents

- [Data Architecture](#-data-architecture)
- [Project Overview](#-project-overview)
- [Tools & Resources](#-tools--resources)
- [Project Requirements](#-project-requirements)
  - [Data Warehouse Construction](#1-data-warehouse-construction-data-engineering)
  - [Analytics & Reporting](#2-analytics--reporting-data-analysis)
- [Repository Structure](#-repository-structure)
- [Getting Started](#-getting-started)
- [License](#-license)
- [About the Author](#-about-the-author)

---

## 🏗️ Data Architecture

The project follows the **Medallion Architecture** with three logical layers:

![Data Architecture](docs/data_architecture.png)

| Layer   | Purpose                                                                 |
|---------|-------------------------------------------------------------------------|
| **Bronze** | Stores raw data exactly as received from source systems (CSV files). |
| **Silver** | Applies data cleansing, standardization, and normalization.           |
| **Gold**   | Contains business-ready data modeled in a star schema for analytics.  |

---

## 📖 Project Overview

This project covers the full lifecycle of a modern data warehouse:

1. **Data Architecture** – Design using the Medallion pattern (Bronze, Silver, Gold).
2. **ETL Pipelines** – Extract, transform, and load data from source to warehouse.
3. **Data Modeling** – Build fact and dimension tables optimized for analytical queries.
4. **Analytics & Reporting** – Deliver SQL-based reports and dashboards for decision-making.

🎯 This repository is ideal for professionals and students looking to demonstrate expertise in:

- SQL Development  
- Data Architecture  
- Data Engineering  
- ETL Pipeline Development  
- Data Modeling  
- Data Analytics  

---

## 🛠️ Tools & Resources

Everything is **free**!

| Tool | Purpose |
|------|---------|
| [Datasets](datasets/) | Project CSV files |
| [SQL Server Express](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) | Lightweight database server |
| [SQL Server Management Studio (SSMS)](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms) | Database management GUI |
| [GitHub](https://github.com/) | Version control and collaboration |
| [DrawIO](https://www.drawio.com/) | Architecture and flow diagrams |
| [Notion](https://www.notion.com/) | Project management |
| [Notion Project Steps](https://thankful-pangolin-2ca.notion.site/SQL-Data-Warehouse-Project-16ed041640ef80489667cfe2f380b269?pvs=4) | Full project roadmap |

---

## 🚀 Project Requirements

### 1. Data Warehouse Construction (Data Engineering)

**Objective**  
Build a modern data warehouse using SQL Server to consolidate sales data and enable analytical reporting.

**Specifications**
- **Data Sources** – Two source systems (ERP and CRM) provided as CSV files.
- **Data Quality** – Cleanse and resolve issues before analysis.
- **Integration** – Combine both sources into a single, user-friendly analytical model.
- **Scope** – Focus on the latest dataset only (no historization required).
- **Documentation** – Provide clear data model documentation for business and analytics teams.

---

### 2. Analytics & Reporting (Data Analysis)

**Objective**  
Deliver SQL-based insights into:

- **Customer Behavior**  
- **Product Performance**  
- **Sales Trends**

These insights empower stakeholders with key metrics for strategic decision-making.

📄 For detailed requirements, see [docs/requirements.md](docs/requirements.md).

---

## 📂 Repository Structure


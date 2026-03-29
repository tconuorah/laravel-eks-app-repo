# Platform Engineering Tech

## Overview

This project provisions a local **Laravel application environment** using **Docker Compose**.
The stack consists of **NGINX**, **PHP-FPM**, and **MySQL**, allowing the Laravel application to run in a containerized environment while being served through NGINX on port **8080**.

The goal of this setup is to demonstrate how multiple services can be orchestrated using Docker Compose while ensuring proper networking, database connectivity, and structured logging.

---

# Architecture

The application stack consists of three main services:

```
Browser
   │
   ▼
NGINX (Port 8080)
   │
   ▼
PHP-FPM (Laravel Application)
   │
   ▼
MySQL Database
```

### Service Responsibilities

**NGINX**

* Serves the Laravel application
* Routes requests to the `public/` directory
* Forwards PHP requests to the PHP-FPM container
* Emits **JSON formatted access logs**

**PHP-FPM**

* Executes the Laravel application
* Processes PHP requests received from NGINX

**MySQL**

* Provides the application database
* Persists data using a Docker volume

All services communicate over an internal **Docker network**.

---

# Prerequisites

Ensure the following are installed:

* Docker
* Docker Compose

Verify installation:

```bash
docker --version
docker compose version
```

---

# Setup Instructions

### 1. Clone the repository

```bash
git clone <repository-url>
cd platform-engin
```

---

### 2. Start the services

Build and start the containers:

```bash
docker compose up -d --build
```

This will start:

* `nginx`
* `php`
* `mysql`

---

### 3. Install Laravel dependencies

```bash
docker compose run --rm composer
```

---

### 4. Clear Laravel configuration cache

```bash
docker compose exec php php artisan config:clear
```

---

### 5. Run database migrations

```bash
docker compose exec php php artisan migrate
```

This initializes the database schema and creates the required tables.

---

# Accessing the Application

Once the containers are running, the Laravel application can be accessed at:

```
http://localhost:8080
```

You should see the **Laravel welcome page**.

---

# Logging

NGINX access logs are configured to output in **JSON format**.

Example log entry:

```json
{
 "time_local":"06/Mar/2026:23:05:17 +0000",
 "remote_addr":"192.168.65.1",
 "request":"GET / HTTP/1.1",
 "status":"200",
 "body_bytes_sent":"27551",
 "request_time":"0.029"
}
```

This structured format makes logs easier to ingest into centralized logging systems such as:

* Elasticsearch
* Splunk
* Datadog
* Loki

---

# Database Configuration

The Laravel application connects to MySQL using the following environment variables:

```
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=rootpass
```

The `DB_HOST` value corresponds to the **Docker Compose service name**, allowing containers to communicate over the Docker network.

---

# Verifying the Environment

To verify the stack is running correctly:

### Check running containers

```bash
docker compose ps
```

You should see:

* nginx
* php
* mysql

---

### Verify database tables

```bash
docker compose exec mysql mysql -u root -p
```

Enter password:

```
rootpass
```

Then run:

```sql
USE laravel;
SHOW TABLES;
```

---

# Data Persistence

MySQL data is stored in a Docker volume:

```
mysql_data
```

This ensures database data persists even if containers are restarted.

---

# Reliability Improvements

To improve container startup reliability:

* A **MySQL healthcheck** is configured
* The **PHP service waits for MySQL to become healthy** before starting

This prevents situations where the application attempts to connect to the database before it is ready.

---

# Tradeoffs and Notes

For simplicity in this challenge:

* The MySQL root user is used for database access
* MySQL is exposed on port `3306` for easier debugging

In a production environment, the following improvements would be recommended:

* Use a dedicated database user instead of root
* Implement secrets management
* Add container resource limits
* Integrate centralized logging and monitoring

---

# Stopping the Environment

To stop the containers:

```bash
docker compose down
```

To remove containers and volumes:

```bash
docker compose down -v
```

---

# Summary

This solution demonstrates:

* Container orchestration using **Docker Compose**
* Serving Laravel through **NGINX + PHP-FPM**
* MySQL integration with Laravel
* JSON structured logging
* Persistent storage using Docker volumes
* Service dependency management for reliable startup

The environment provides a reproducible local development setup for running the Laravel application in a containerized stack.

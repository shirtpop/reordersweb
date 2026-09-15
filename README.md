# Shirtpop Ordering Platform

A Ruby on Rails 8 application for managing clients, projects, products, and orders.  
The app uses PostgreSQL with multiple schemas (`public` for main models, `solid_queue` for background jobs, `solid_cable` for Action Cable / Turbo Streams), Devise for authentication, TailwindCSS + Flowbite for UI, Hotwire (Turbo + Stimulus) for interactivity, and Solid Queue for background jobs.

---

## Requirements

- Ruby 3.x
- Rails 8.x
- PostgreSQL 14+
- Node.js & Yarn
- Redis (optional, only if you choose Redis for caching instead of Solid Cache)
- Docker (for Mailcatcher and optional services)

---

## Installation using docker

1. **Clone the repository**
   ```sh
   git clone https://github.com/your-org/shirtpop.git
   cd shirtpop
2. **Build the image**
   ```sh
   docker-compose build
   docker-compose up -d
3. **Run the server**
   ```sh
   docker-compose exec web bin/dev
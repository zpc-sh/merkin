# Docker Setup for Pactis Phoenix Application

This document provides comprehensive instructions for running the Pactis Phoenix application using Docker in both development and production environments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Development Environment](#development-environment)
- [Production Environment](#production-environment)
- [Environment Configuration](#environment-configuration)
- [Database Management](#database-management)
- [Troubleshooting](#troubleshooting)
- [Performance Tuning](#performance-tuning)

## Prerequisites

### Required Software

- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **Git**: For cloning the repository

### Installation

#### macOS
```bash
brew install docker docker-compose
```

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

#### Verify Installation
```bash
docker --version
docker-compose --version
```

## Quick Start

### Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ash_blueprints
   ```

2. **Setup environment**
   ```bash
   cp .env.dev .env
   # Edit .env with your configuration if needed
   ```

3. **Start development environment**
   ```bash
   ./scripts/docker-dev.sh start
   ```

4. **Access the application**
   - Application: http://localhost:4000
   - Database: localhost:5432 (postgres/postgres)
   - Redis: localhost:6379

### Production Setup

1. **Setup production environment**
   ```bash
   cp .env.prod .env
   # IMPORTANT: Edit .env with secure production values!
   ```

2. **Generate secret key**
   ```bash
   # Generate a secure secret key
   docker run --rm hexpm/elixir:1.18.4-erlang-27.2.2-debian-bookworm-20250109-slim \
     sh -c "mix local.hex --force && mix phx.gen.secret"
   ```

3. **Deploy production environment**
   ```bash
   ./scripts/docker-prod.sh deploy
   ```

4. **Access the application**
   - Application: https://your-domain.com
   - Nginx logs: `docker-compose --profile prod logs nginx`

## Development Environment

### Available Services

- **app_dev**: Phoenix application (development mode)
- **postgres**: PostgreSQL database
- **redis**: Redis cache
- **migrate_dev**: Database migration service
- **setup_dev**: Database setup service

### Development Commands

#### Start/Stop Services
```bash
# Start in foreground (with logs)
./scripts/docker-dev.sh start

# Start in background
./scripts/docker-dev.sh start-bg

# Stop all services
./scripts/docker-dev.sh stop

# Restart services
./scripts/docker-dev.sh restart
```

#### Development Tools
```bash
# View logs
./scripts/docker-dev.sh logs app_dev
./scripts/docker-dev.sh logs postgres

# Open shell in container
./scripts/docker-dev.sh shell app_dev

# Run mix commands
./scripts/docker-dev.sh mix deps.get
./scripts/docker-dev.sh mix test
./scripts/docker-dev.sh mix phx.gen.schema Blog.Post posts title:string
```

#### Database Operations
```bash
# Run migrations
./scripts/docker-dev.sh db-migrate

# Reset database
./scripts/docker-dev.sh db-reset

# Seed database
./scripts/docker-dev.sh db-seed
```

#### Maintenance
```bash
# Rebuild containers
./scripts/docker-dev.sh rebuild

# Clean up resources
./scripts/docker-dev.sh clean

# Check status
./scripts/docker-dev.sh status
```

### Development Workflow

1. **Start the development environment**
   ```bash
   ./scripts/docker-dev.sh start-bg
   ```

2. **Make code changes**
   - Code changes are automatically reloaded via Phoenix Live Reload
   - Static assets are rebuilt automatically

3. **Run database migrations when needed**
   ```bash
   ./scripts/docker-dev.sh mix ecto.migrate
   ```

4. **Run tests**
   ```bash
   ./scripts/docker-dev.sh test
   ```

### File Synchronization

Development mode uses volume mounts for live code reloading:

- `./`: Mounted to `/app` (full project sync)
- `_build/`, `deps/`, `node_modules/`: Excluded via anonymous volumes

## Production Environment

### Available Services

- **app_prod**: Phoenix application (production mode)
- **postgres**: PostgreSQL database
- **redis**: Redis cache
- **nginx**: Reverse proxy and load balancer
- **migrate_prod**: Production database migration service

### Production Commands

#### Deployment
```bash
# Full deployment (build + migrate + start)
./scripts/docker-prod.sh deploy

# Build production images
./scripts/docker-prod.sh build

# Start services
./scripts/docker-prod.sh start
```

#### Monitoring
```bash
# Check application health
./scripts/docker-prod.sh health

# View service status
./scripts/docker-prod.sh status

# View logs
./scripts/docker-prod.sh logs app_prod
./scripts/docker-prod.sh logs nginx
./scripts/docker-prod.sh logs-all
```

#### Database Management
```bash
# Run migrations
./scripts/docker-prod.sh migrate

# Create backup
./scripts/docker-prod.sh backup

# Restore from backup
./scripts/docker-prod.sh restore backups/cdfm_backup_20250118_120000.sql
```

#### Scaling and Updates
```bash
# Scale application instances
./scripts/docker-prod.sh scale 3

# Update deployment
./scripts/docker-prod.sh update

# Clean up old resources
./scripts/docker-prod.sh cleanup
```

### SSL/HTTPS Setup

1. **Obtain SSL certificates**
   ```bash
   # Create ssl directory
   mkdir -p ssl

   # For Let's Encrypt (example)
   certbot certonly --webroot -w /var/www/html -d your-domain.com
   cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
   cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem
   ```

2. **Update nginx configuration**
   - Edit `nginx/conf.d/default.conf`
   - Update `server_name` to your domain
   - Verify SSL certificate paths

3. **Update environment variables**
   ```bash
   # In .env.prod
   PHX_HOST=your-domain.com
   NGINX_HTTPS_PORT=443
   ```

## Environment Configuration

### Development (.env.dev)

```bash
# Application
MIX_ENV=dev
PHX_HOST=localhost
PORT=4000

# Database
POSTGRES_DB=cdfm_dev
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# Security (development only)
SECRET_KEY_BASE=dev_secret_key_here
```

### Production (.env.prod)

```bash
# Application
MIX_ENV=prod
PHX_HOST=your-domain.com
PORT=4000

# Database
POSTGRES_DB=cdfm_prod
POSTGRES_USER=postgres
POSTGRES_PASSWORD=secure_production_password

# Security (CRITICAL: Use secure values!)
SECRET_KEY_BASE=secure_64_character_secret_key_generated_with_mix_phx_gen_secret

# Performance
POOL_SIZE=20
```

### Environment Variables Reference

| Variable | Development | Production | Description |
|----------|------------|------------|-------------|
| `MIX_ENV` | `dev` | `prod` | Elixir environment |
| `PHX_HOST` | `localhost` | `your-domain.com` | Phoenix host |
| `PORT` | `4000` | `4000` | Application port |
| `DATABASE_URL` | Auto-generated | Required | Database connection URL |
| `SECRET_KEY_BASE` | Development key | **Must generate** | Phoenix secret key |
| `POSTGRES_PASSWORD` | `postgres` | **Must secure** | Database password |
| `POOL_SIZE` | `10` | `20` | Database connection pool |

## Database Management

### Migrations

```bash
# Development
./scripts/docker-dev.sh mix ecto.migrate

# Production
./scripts/docker-prod.sh migrate
```

### Backups

```bash
# Create backup
./scripts/docker-prod.sh backup

# Backups are stored in ./backups/ directory
# Format: cdfm_backup_YYYYMMDD_HHMMSS.sql
```

### Restoration

```bash
# Restore from backup
./scripts/docker-prod.sh restore backups/cdfm_backup_20250118_120000.sql
```

### Database Connection

#### Development
- Host: `localhost`
- Port: `5432`
- Database: `cdfm_dev`
- Username: `postgres`
- Password: `postgres`

#### Production
- Host: Internal Docker network
- Port: `5432`
- Database: `cdfm_prod`
- Username: `postgres`
- Password: As configured in `.env`

## Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Check what's using the port
lsof -i :4000

# Kill the process
sudo kill -9 <PID>

# Or use different port
export PORT=4001
```

#### 2. Database Connection Issues
```bash
# Check PostgreSQL status
./scripts/docker-dev.sh logs postgres

# Reset database
./scripts/docker-dev.sh db-reset

# Check database connectivity
docker-compose --profile dev exec postgres pg_isready -U postgres
```

#### 3. Permission Issues
```bash
# Fix file permissions
sudo chown -R $USER:$USER .

# Rebuild containers
./scripts/docker-dev.sh rebuild
```

#### 4. Out of Disk Space
```bash
# Clean up Docker resources
docker system prune -a
docker volume prune

# Or use script
./scripts/docker-prod.sh cleanup
```

### Debugging

#### View Application Logs
```bash
# Development
./scripts/docker-dev.sh logs app_dev

# Production
./scripts/docker-prod.sh logs app_prod
```

#### Interactive Shell
```bash
# Development
./scripts/docker-dev.sh shell app_dev

# Production
docker-compose --profile prod exec app_prod /bin/sh
```

#### Database Shell
```bash
# PostgreSQL shell
docker-compose --profile dev exec postgres psql -U postgres cdfm_dev

# Redis shell
docker-compose --profile dev exec redis redis-cli
```

## Performance Tuning

### Production Optimizations

#### Database
```bash
# Increase connection pool
POOL_SIZE=30

# Enable connection pooling
# (Already configured in application)
```

#### Application Scaling
```bash
# Scale application instances
./scripts/docker-prod.sh scale 4

# Monitor resource usage
docker stats
```

#### Nginx Tuning

Edit `nginx/nginx.conf`:

```nginx
# Increase worker connections
worker_connections 2048;

# Enable keepalive
keepalive_timeout 65;
keepalive_requests 100;

# Optimize buffers
proxy_buffer_size 4k;
proxy_buffers 8 4k;
```

### Monitoring

#### Health Checks
```bash
# Application health
./scripts/docker-prod.sh health

# Individual service health
docker-compose --profile prod exec app_prod curl -f http://localhost:4000/health
```

#### Resource Monitoring
```bash
# Container resource usage
docker stats

# Service logs
./scripts/docker-prod.sh logs-all
```

#### Performance Metrics

Monitor these key metrics:

- Response time: `< 200ms` average
- Memory usage: `< 512MB` per instance
- Database connections: `< 80%` of pool size
- Error rate: `< 1%` of requests

## Development Tips

### Hot Reloading
- Code changes trigger automatic recompilation
- Static assets are rebuilt automatically
- Database changes require migration runs

### Testing
```bash
# Run all tests
./scripts/docker-dev.sh test

# Run specific tests
./scripts/docker-dev.sh mix test test/specific_test.exs

# Run tests with coverage
./scripts/docker-dev.sh mix test --cover
```

### Code Quality
```bash
# Format code
./scripts/docker-dev.sh mix format

# Run precommit checks
./scripts/docker-dev.sh mix precommit

# Check dependencies
./scripts/docker-dev.sh mix deps.audit
```

## Security Considerations

### Production Security

1. **Environment Variables**
   - Use strong, unique passwords
   - Generate secure SECRET_KEY_BASE
   - Never commit .env files with secrets

2. **SSL/TLS**
   - Use valid SSL certificates
   - Enable HTTPS redirect
   - Configure security headers

3. **Database**
   - Use strong database passwords
   - Limit database access
   - Enable encryption at rest

4. **Network**
   - Use internal Docker networks
   - Limit external port exposure
   - Configure firewall rules

### Development Security

1. **Local Development**
   - Use .env.dev for development
   - Keep development credentials simple
   - Don't use production data locally

2. **Container Security**
   - Run as non-root user (production)
   - Keep images updated
   - Scan for vulnerabilities

## Support

### Getting Help

- Check logs: `./scripts/docker-dev.sh logs`
- Review this documentation
- Check Docker and Phoenix documentation
- Verify environment configuration

### Common Commands Quick Reference

```bash
# Development
./scripts/docker-dev.sh start-bg    # Start development
./scripts/docker-dev.sh stop        # Stop development
./scripts/docker-dev.sh logs        # View logs
./scripts/docker-dev.sh shell       # Open shell
./scripts/docker-dev.sh mix test    # Run tests

# Production
./scripts/docker-prod.sh deploy     # Deploy production
./scripts/docker-prod.sh health     # Check health
./scripts/docker-prod.sh backup     # Create backup
./scripts/docker-prod.sh scale 3    # Scale to 3 instances
```

For additional help, run:
```bash
./scripts/docker-dev.sh help
./scripts/docker-prod.sh help
```

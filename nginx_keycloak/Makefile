.PHONY: help build up down logs clean restart status keycloak-setup

# Default target
help:
	@echo "Available commands:"
	@echo "  build         - Build all Docker images"
	@echo "  up           - Start all services"
	@echo "  down         - Stop all services"
	@echo "  logs         - Show logs for all services"
	@echo "  clean        - Clean up containers, networks, and volumes"
	@echo "  restart      - Restart all services"
	@echo "  status       - Show status of all services"
	@echo "  keycloak-setup - Show Keycloak setup instructions"

# Build all images
build:
	docker-compose build

# Start all services
up:
	docker-compose up -d
	@echo "Services starting..."
	@echo "Waiting for services to be ready..."
	@sleep 10
	@echo "Services should be available at:"
	@echo "  - Application: http://localhost"
	@echo "  - Keycloak Admin: http://localhost:8080"
	@echo "  - Express App Direct: http://localhost:3000"

# Stop all services
down:
	docker-compose down

# Show logs
logs:
	docker-compose logs -f

# Clean up everything
clean:
	docker-compose down -v --remove-orphans
	docker system prune -f

# Restart services
restart: down up

# Show service status
status:
	docker-compose ps
	@echo ""
	@echo "Service Health:"
	@docker-compose exec -T app curl -s http://localhost:3000/health || echo "App not ready"
	@docker-compose exec -T keycloak curl -s http://localhost:8080/health/ready || echo "Keycloak not ready"

# Show Keycloak setup instructions
keycloak-setup:
	@echo "Keycloak Setup Instructions:"
	@echo "1. Access Keycloak admin console: http://localhost:8080"
	@echo "2. Login with: admin / admin123"
	@echo "3. Create a new client:"
	@echo "   - Client ID: nginx-client"
	@echo "   - Client Protocol: openid-connect"
	@echo "   - Access Type: confidential"
	@echo "   - Valid Redirect URIs: http://localhost/callback"
	@echo "   - Web Origins: http://localhost"
	@echo "4. Copy the client secret from the Credentials tab"
	@echo "5. Update the KEYCLOAK_CLIENT_SECRET in .env file"
	@echo "6. Restart services: make restart"

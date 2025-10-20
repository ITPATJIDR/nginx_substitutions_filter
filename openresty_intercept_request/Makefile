.PHONY: up down logs restart clean

up:
	docker-compose up -d

down:
	docker-compose down

logs:
	docker-compose logs -f

restart:
	docker-compose restart

clean:
	docker-compose down -v
	docker system prune -f

build:
	docker-compose build

rebuild:
	docker-compose build --no-cache
	docker-compose up -d


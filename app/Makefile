.PHONY: up down restart logs ps shell migrate

up:
	docker compose up -d --build

down:
	docker compose down

restart:
	docker compose down && docker compose up -d --build

logs:
	docker compose logs -f

ps:
	docker compose ps

shell:
	docker compose exec php sh

migrate:
	docker compose exec php php artisan migrate

Check database:
	docker compose exec mysql mysql -u root -p

seed:
	docker compose exec php php artisan db:seed
.PHONY: setup up down logs dev clean migrate

## setup — Full bootstrap: checks deps, creates .env, builds & starts everything
setup:
	@chmod +x setup.sh && ./setup.sh

## up — Build images and start all services in detached mode
up:
	docker compose up --build -d

## down — Stop all services and remove volumes
down:
	docker compose down -v

## logs — Stream app logs
logs:
	docker compose logs -f app

## dev — Start services in foreground (useful during development)
dev:
	docker compose up --build

## clean — Remove node_modules
clean:
	rm -rf node_modules

## migrate — Run init SQL against the running database container
migrate:
	docker compose exec -T db psql -U ebot_user -d ebot < db/docker-init.sql

.PHONY: up prod

up:
	docker compose -f docker-compose-dev.yaml up --build

prod:
	docker compose up --build

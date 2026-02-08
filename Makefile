.PHONY: up prod pass down clean

up:
	docker compose -f docker-compose-dev.yaml up --build

prod:
	docker compose up --build

hash:
	@test -f "$(CURDIR)/scripts/generate_pass_hash.py" || \
		( echo "Error: script not found: $(CURDIR)/scripts/generate_pass_hash.py" && exit 1 )
	@echo "Starting python:3.14-alpine container..."
	@docker run --rm \
		-v "$(CURDIR)/scripts/generate_pass_hash.py:/generate_pass_hash.py" \
		python:3.14-alpine sh -c '\
			pip install bcrypt > /dev/null 2>&1 && \
			python3 /generate_pass_hash.py "$(filter-out $@,$(MAKECMDGOALS))" \
		'

down:
	docker compose -f docker-compose-dev.yaml down

clean: down
	docker volume rm prometheus-coolify_prometheus-data || true
	docker volume rm prometheus-coolify_grafana-data || true
	docker volume rm prometheus-coolify_grafana-dashboards || true

%:
	@:

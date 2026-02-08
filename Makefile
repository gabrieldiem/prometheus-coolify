.PHONY: up prod

up:
	docker compose -f docker-compose-dev.yaml up --build

prod:
	docker compose up --build

pass:
	@test -f "$(CURDIR)/generate_pass.py" || \
		( echo "Error: script not found: $(CURDIR)/generate_pass.py" && exit 1 )
	@echo "Starting python:3.14-alpine container..."
	@docker run --rm \
		-v "$(CURDIR)/generate_pass.py:/generate_pass.py" \
		python:3.14-alpine sh -c '\
			pip install bcrypt > /dev/null 2>&1 && \
			python3 /generate_pass.py "$(filter-out $@,$(MAKECMDGOALS))" \
		'

%:
	@:

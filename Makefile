.PHONY: all

all:
	docker build --progress=plain -t apache2-php5:latest .

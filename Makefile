.PHONY: 10.0-galera 10.0

10.0:
	docker build -t hauptmedia/mariadb:10.0 10.0

10.0-galera:
	docker build -t hauptmedia/mariadb:10.0-galera 10.0-galera



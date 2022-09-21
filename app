#!/bin/bash

# Build all of the images or the specified one
build () {
    docker-compose build "${@:1}"
}

# Generate a wildcard certificate
cert_generate () {
    sudo rm -Rf server/certs/flask-redis.test.*
    docker-compose run --rm nginx_server sh -c "cd /etc/nginx/certs && touch openssl.cnf && cat /etc/ssl/openssl.cnf > openssl.cnf && echo \"\" >> openssl.cnf && echo \"[ SAN ]\" >> openssl.cnf && echo \"subjectAltName=DNS.1:flask-redis.test,DNS.2:*.flask-redis.test\" >> openssl.cnf && openssl req -x509 -sha256 -nodes -newkey rsa:4096 -keyout flask-redis.test.key -out flask-redis.test.crt -days 3650 -subj \"/CN=*.flask-redis.test\" -config openssl.cnf -extensions SAN && rm openssl.cnf"
}

# Install the certificate
cert_install () {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain server/certs/flask-redis.test.crt
    elif [[ "$OSTYPE" == "linux-gnu" ]]; then
        sudo rm -r /usr/local/share/ca-certificates/flask-redis.test.crt
        sudo ln -s "$(pwd)/server/certs/flask-redis.test.crt" /usr/local/share/ca-certificates/flask-redis.test.crt
        sudo update-ca-certificates --fresh

        # FOR WSL - ADD THIS TO YOUR LOCAL WINDOWS TRUSTED CERTS
        # https://www.thewindowsclub.com/manage-trusted-root-certificates-windows
        cp "$(pwd)/server/certs/flask-redis.test.crt" /mnt/c/TEMP/

        echo "ADD THE CERT TO THE WINDOWS LOCAL TRUSTED CERTS IF YOU ARE USING WSL"
    else
        echo "Could not install the certificate on the host machine, please do it manually"
    fi
}

# Remove the entire Docker environment
destroy () {
    read -p "This will delete containers, volumes and images. Are you sure? [y/N]: " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit; fi
    docker-compose down -v --rmi all --remove-orphans
}

# Stop and destroy all containers
down () {
    docker-compose down "${@:1}"
}

# Stop and destroy all containers
fresh () {
    docker-compose down && docker-compose up --build -d
}

# Display and tail the logs
logs () {
    docker-compose logs -f "${@:1}"
}

# Restart the containers
restart () {
    stop && up
}

run () {
    docker-compose run "${@:1}"
}

# Stop the containers
stop () {
    docker-compose stop
}

# Create and start the containers and volumes
up () {
    docker-compose up -d
}

# Run a Yarn command
yarn () {
    docker-compose run --rm nuxt_frontend yarn "${@:1}"
}

#######################################
# MENU
#######################################

case "$1" in
    backend:test)
        backend:test
        ;;
    build)
        build "${@:2}"
        ;;
    cert)
        case "$2" in
            generate)
                cert_generate
                ;;
            install)
                cert_install
                ;;
            *)
                cat << EOF
Certificate management commands.
Usage:
    cylinder cert <command>
Available commands:
    generate .................................. Generate a new certificate
    install ................................... Install the certificate
    dhparam ................................... PROD STUFF
EOF
                ;;
        esac
        ;;
    destroy)
        destroy
        ;;
    down)
        down "${@:2}"
        ;;
    fresh)
        fresh
        ;;
    restart)
        restart
        ;;
    run)
        run "${@:2}"
        ;;
    logs)
        logs "${@:2}"
        ;;
    stop)
        stop
        ;;
    up)
        up
        ;;
    yarn)
        yarn "${@:2}"
        ;;
    *)
        cat << EOF
Command line interface for the Docker-based web development environment cylinder.
Usage:
    cylinder <command> [options] [arguments]
Available commands:
    build [image] ............................. Build all of the images or the specified one
    cert ...................................... Certificate management commands
        generate .............................. Generate a new certificate
        install ............................... Install the certificate
    destroy ................................... Remove the entire Docker environment
    down [-v] ................................. Stop and destroy all containers
                                                Options:
                                                    -v .................... Destroy the volumes as well
    logs [container] .......................... Display and tail the logs of all containers or the specified one's
    restart ................................... Restart the containers
    start ..................................... Start the containers
    stop ...................................... Stop the containers
    up ........................................ Build and start the containers
    yarn ...................................... Run an Yarn command
EOF
        exit 1
        ;;
esac

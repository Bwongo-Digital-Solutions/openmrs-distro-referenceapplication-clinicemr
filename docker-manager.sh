#!/bin/bash

# Docker Management Script for OpenMRS Reference Application
# Provides interactive menu for common Docker operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to build containers
build_containers() {
    print_header "Building Containers"
    docker-compose build
    print_success "Containers built successfully"
}

# Function to start containers
start_containers() {
    print_header "Starting Containers"
    docker-compose up -d
    print_success "Containers started successfully"
}

# Function to stop containers
stop_containers() {
    print_header "Stopping Containers"
    docker-compose stop
    print_success "Containers stopped successfully"
}

# Function to delete containers
delete_containers() {
    print_header "Deleting Containers"
    read -p "Are you sure you want to delete all containers? (y/n): " confirm
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        docker-compose down
        print_success "Containers deleted successfully"
    else
        print_warning "Operation cancelled"
    fi
}

# Function to prune containers
prune_containers() {
    print_header "Pruning Docker System"
    read -p "This will remove all unused containers, networks, images, and volumes. Continue? (y/n): " confirm
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        docker system prune -a --volumes
        print_success "Docker system pruned successfully"
    else
        print_warning "Operation cancelled"
    fi
}

# Function to show logs
show_logs() {
    print_header "Showing Container Logs"
    echo "Select service to view logs:"
    echo "1) All services"
    echo "2) Gateway"
    echo "3) Frontend"
    echo "4) Backend"
    echo "5) Database"
    read -p "Enter choice (1-5): " log_choice
    
    case $log_choice in
        1)
            docker-compose logs -f
            ;;
        2)
            docker-compose logs -f gateway
            ;;
        3)
            docker-compose logs -f frontend
            ;;
        4)
            docker-compose logs -f backend
            ;;
        5)
            docker-compose logs -f db
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Function to restart containers
restart_containers() {
    print_header "Restarting Containers"
    docker-compose restart
    print_success "Containers restarted successfully"
}

# Function to copy static assets without rebuilding
copy_static_assets() {
    print_header "Copying Static Assets"
    echo "Select service to copy assets to:"
    echo "1) Frontend"
    echo "2) Gateway"
    read -p "Enter choice (1-2): " asset_choice
    
    read -p "Enter source path (local): " source_path
    read -p "Enter destination path (in container): " dest_path
    
    case $asset_choice in
        1)
            container_name=$(docker-compose ps -q frontend | xargs docker inspect -f '{{.Name}}' | sed 's/\///')
            if [ -n "$container_name" ]; then
                docker cp "$source_path" "$container_name:$dest_path"
                print_success "Assets copied to frontend container"
            else
                print_error "Frontend container not running"
            fi
            ;;
        2)
            container_name=$(docker-compose ps -q gateway | xargs docker inspect -f '{{.Name}}' | sed 's/\///')
            if [ -n "$container_name" ]; then
                docker cp "$source_path" "$container_name:$dest_path"
                print_success "Assets copied to gateway container"
            else
                print_error "Gateway container not running"
            fi
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Function to rebuild with no cache
rebuild_no_cache() {
    print_header "Rebuilding Containers (No Cache)"
    docker-compose build --no-cache
    print_success "Containers rebuilt without cache"
    read -p "Do you want to restart the containers? (y/n): " restart
    if [[ $restart == "y" || $restart == "Y" ]]; then
        docker-compose up -d
        print_success "Containers restarted successfully"
    fi
}

# Function to show container status
show_status() {
    print_header "Container Status"
    docker-compose ps
}

# Function to view resource usage
show_resources() {
    print_header "Resource Usage"
    docker stats --no-stream
}

# Main menu function
show_menu() {
    clear
    print_header "Docker Management Menu"
    echo "1) Build containers"
    echo "2) Start containers"
    echo "3) Stop containers"
    echo "4) Delete containers"
    echo "5) Prune containers (remove unused resources)"
    echo "6) Show logs"
    echo "7) Restart containers"
    echo "8) Copy static assets (without rebuilding)"
    echo "9) Rebuild with no cache"
    echo "10) Show container status"
    echo "11) Show resource usage"
    echo "12) Exit"
    echo ""
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (1-12): " choice
    
    case $choice in
        1)
            build_containers
            ;;
        2)
            start_containers
            ;;
        3)
            stop_containers
            ;;
        4)
            delete_containers
            ;;
        5)
            prune_containers
            ;;
        6)
            show_logs
            ;;
        7)
            restart_containers
            ;;
        8)
            copy_static_assets
            ;;
        9)
            rebuild_no_cache
            ;;
        10)
            show_status
            ;;
        11)
            show_resources
            ;;
        12)
            print_success "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please enter a number between 1 and 12."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done

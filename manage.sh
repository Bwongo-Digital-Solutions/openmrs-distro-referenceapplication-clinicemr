#!/bin/bash

# OpenMRS Docker Management Script
# This script helps manage the OpenMRS Docker environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
${GREEN}╔════════════════════════════════════════════════════════════╗${NC}
${GREEN}║         ClinicEMR - Docker Management Script              ║${NC}
${GREEN}╚════════════════════════════════════════════════════════════╝${NC}

${BLUE}Interactive Mode:${NC}
    $0                      # Run without arguments for interactive menu
    $0 menu                 # Explicitly launch interactive menu
    $0 -i                   # Same as above

${BLUE}Command-Line Mode:${NC}

Usage: $0 [COMMAND] [OPTIONS]

${BLUE}Basic Commands:${NC}
    build           Build all Docker images
    start           Start all containers
    stop            Stop all containers
    restart         Restart all containers
    logs            Show logs (use -f to follow)
    status          Show status of all containers
    rebuild         Clean, build and start containers
    build-start     Build images and start containers
    watch           Watch for changes and rebuild automatically
    dev             Start in development mode with hot reload
    dev-logs        Start dev mode and follow logs
    
${BLUE}Docker Hub Commands:${NC}
    push            Build and push images to Docker Hub
    tag             Tag images with custom tag (usage: tag <tag-name>)
    
${BLUE}SSL Commands:${NC}
    start-ssl       Start with SSL enabled
    stop-ssl        Stop SSL-enabled containers
    
${BLUE}Cleanup Commands:${NC}
    clean           Stop and remove all containers
    clean-volumes   Remove all volumes (⚠️  WARNING: data loss)
    clean-all       Stop containers, remove volumes and images (⚠️  WARNING: destructive)
    
${BLUE}Shell Access:${NC}
    shell [name]    Open shell in a container (backend, frontend, gateway, db)
    
${BLUE}Options:${NC}
    -f, --follow    Follow logs (for logs command)
    -h, --help      Show this help message
    -i, --interactive, menu   Launch interactive menu

${BLUE}Examples:${NC}
    $0                          # Interactive menu
    $0 build                    # Build all images
    $0 start                    # Start containers
    $0 build-start              # Build and start in one command
    $0 watch                    # Watch for changes and auto-rebuild
    $0 dev                      # Start with hot reload (development mode)
    $0 dev-logs                 # Start dev mode and follow logs
    $0 push                     # Build and push to Docker Hub
    $0 tag v1.0.0               # Tag images with v1.0.0
    $0 logs -f                  # Follow logs
    $0 shell backend            # Open shell in backend container
    $0 clean-all                # Remove everything (containers, volumes, images)
    $0 start-ssl                # Start with SSL

EOF
}

# Function to build images
build_images() {
    print_info "Building Docker images..."
    cd "$SCRIPT_DIR"
    docker compose build --no-cache
    print_success "Images built successfully!"
}

# Function to start containers
start_containers() {
    print_info "Starting containers..."
    cd "$SCRIPT_DIR"
    docker compose up -d
    print_success "Containers started!"
    print_info "OpenMRS UI: http://localhost/openmrs/spa"
    print_info "Legacy UI: http://localhost/openmrs"
}

# Function to start with SSL
start_ssl() {
    print_info "Starting containers with SSL..."
    cd "$SCRIPT_DIR"
    docker compose -f docker-compose.yml -f docker-compose.ssl.yml up -d
    print_success "Containers started with SSL!"
    print_info "OpenMRS UI: https://localhost/openmrs/spa"
    print_info "Legacy UI: https://localhost/openmrs"
    print_warning "If using self-signed certificates, your browser will show a security warning."
}

# Function to stop containers
stop_containers() {
    print_info "Stopping containers..."
    cd "$SCRIPT_DIR"
    docker compose down
    print_success "Containers stopped!"
}

# Function to stop SSL containers
stop_ssl() {
    print_info "Stopping SSL containers..."
    cd "$SCRIPT_DIR"
    docker compose -f docker-compose.yml -f docker-compose.ssl.yml down
    print_success "SSL containers stopped!"
}

# Function to restart containers
restart_containers() {
    print_info "Restarting containers..."
    stop_containers
    start_containers
}

# Function to show logs
show_logs() {
    cd "$SCRIPT_DIR"
    if [ "$1" == "-f" ] || [ "$1" == "--follow" ]; then
        print_info "Following logs (Ctrl+C to exit)..."
        docker compose logs -f
    else
        docker compose logs --tail=100
    fi
}

# Function to show status
show_status() {
    print_info "Container status:"
    cd "$SCRIPT_DIR"
    docker compose ps
}

# Function to clean containers
clean_containers() {
    print_warning "This will stop and remove all containers."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cleaning containers..."
        cd "$SCRIPT_DIR"
        docker compose down
        print_success "Containers removed!"
    else
        print_info "Cancelled."
    fi
}

# Function to clean volumes
clean_volumes() {
    print_error "WARNING: This will delete all data including the database!"
    read -p "Are you absolutely sure? Type 'yes' to confirm: " -r
    echo
    if [[ $REPLY == "yes" ]]; then
        print_info "Removing volumes..."
        cd "$SCRIPT_DIR"
        docker compose down -v
        print_success "Volumes removed!"
    else
        print_info "Cancelled."
    fi
}

# Function to clean everything
clean_all() {
    print_error "WARNING: This will remove containers, volumes, and images!"
    print_error "All data will be lost and images will need to be rebuilt!"
    read -p "Are you absolutely sure? Type 'DELETE' to confirm: " -r
    echo
    if [[ $REPLY == "DELETE" ]]; then
        print_info "Removing all resources..."
        cd "$SCRIPT_DIR"
        
        # Stop and remove containers and volumes
        docker compose down -v
        
        # Remove images
        print_info "Removing images..."
        docker compose down --rmi all
        
        # Clean up dangling images and build cache
        print_info "Cleaning up Docker system..."
        docker system prune -f
        
        print_success "All resources removed!"
        print_info "Run '$0 build' to rebuild images."
    else
        print_info "Cancelled."
    fi
}

# Function to rebuild everything
rebuild() {
    print_info "Rebuilding environment..."
    clean_containers
    build_images
    start_containers
}

# Function to build and start
build_and_start() {
    print_info "Building images and starting containers..."
    build_images
    start_containers
}

# Function to start development mode with hot reload
start_dev_mode() {
    print_info "Starting development mode with hot reload..."
    cd "$SCRIPT_DIR"
    
    # Check if dev compose file exists
    if [ ! -f "docker-compose.dev.yml" ]; then
        print_error "docker-compose.dev.yml not found!"
        print_info "Hot reload requires docker-compose.dev.yml"
        exit 1
    fi
    
    print_info "Building development images..."
    docker compose -f docker-compose.yml -f docker-compose.dev.yml build
    
    print_info "Starting containers with volume mounts for hot reload..."
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
    
    print_success "Development mode started!"
    print_info "OpenMRS UI: http://localhost/openmrs/spa"
    print_info "Backend Debug Port: 1044"
    print_info ""
    print_info "${GREEN}Hot Reload Enabled:${NC}"
    print_info "  - Frontend configs: ./frontend/config-core_demo.json"
    print_info "  - Frontend assets: ./frontend/assets/"
    print_info "  - Backend config: ./distro/configuration/"
    print_info ""
    print_warning "Changes to these files will be reflected without rebuild!"
}

# Function to start dev mode and follow logs
start_dev_with_logs() {
    start_dev_mode
    echo ""
    print_info "Following logs (Ctrl+C to exit)..."
    sleep 2
    docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f
}

# Function to stop dev mode
stop_dev_mode() {
    print_info "Stopping development containers..."
    cd "$SCRIPT_DIR"
    docker compose -f docker-compose.yml -f docker-compose.dev.yml down
    print_success "Development containers stopped!"
}

# Function to watch for changes and rebuild
watch_and_rebuild() {
    print_info "Starting watch mode..."
    print_info "Watching for changes in Dockerfiles and docker-compose files"
    print_warning "Press Ctrl+C to stop watching"
    print_info ""
    print_info "${YELLOW}TIP:${NC} For hot reload without rebuild, use 'dev' mode instead!"
    echo ""
    
    cd "$SCRIPT_DIR"
    
    # Check if inotify-tools is installed
    if ! command -v inotifywait &> /dev/null; then
        print_error "inotifywait is not installed."
        print_info "Install it with: sudo apt-get install inotify-tools (Debian/Ubuntu)"
        print_info "                 sudo yum install inotify-tools (RHEL/CentOS)"
        print_info ""
        print_info "Falling back to polling mode (checking every 5 seconds)..."
        watch_polling
        return
    fi
    
    # Initial build and start
    build_and_start
    
    # Watch for changes
    while true; do
        inotifywait -e modify,create,delete -r \
            --include '(Dockerfile|docker-compose.*\.yml)$' \
            "$SCRIPT_DIR" 2>/dev/null
        
        print_warning "Changes detected! Rebuilding in 2 seconds..."
        sleep 2
        
        print_info "Stopping containers..."
        docker compose down
        
        print_info "Rebuilding and restarting..."
        build_and_start
        
        print_info "Waiting for next change..."
    done
}

# Function to push images to Docker Hub
push_to_dockerhub() {
    print_info "Building and pushing images to Docker Hub..."
    echo ""
    
    # Check if user is logged in to Docker Hub
    if ! docker info | grep -q "Username"; then
        print_warning "You are not logged in to Docker Hub."
        read -p "Do you want to login now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker login
            if [ $? -ne 0 ]; then
                print_error "Docker login failed. Aborting push."
                return 1
            fi
        else
            print_error "Cannot push without Docker Hub authentication."
            return 1
        fi
    fi
    
    cd "$SCRIPT_DIR"
    
    # Get Docker Hub username/organization
    print_info "Enter your Docker Hub username or organization name:"
    read -p "Docker Hub username: " DOCKER_USERNAME
    
    if [ -z "$DOCKER_USERNAME" ]; then
        print_error "Username cannot be empty."
        return 1
    fi
    
    # Get tag (default to 'latest')
    print_info "Enter tag for images (default: latest):"
    read -p "Tag: " IMAGE_TAG
    IMAGE_TAG=${IMAGE_TAG:-latest}
    
    print_info "Building images..."
    docker compose build --no-cache
    
    if [ $? -ne 0 ]; then
        print_error "Build failed. Aborting push."
        return 1
    fi
    
    # Define images to push
    declare -a IMAGES=("gateway" "frontend" "backend")
    
    print_info "Tagging and pushing images..."
    echo ""
    
    for IMAGE in "${IMAGES[@]}"; do
        LOCAL_IMAGE="openmrs-03-distro-clinicemr-${IMAGE}"
        REMOTE_IMAGE="${DOCKER_USERNAME}/openmrs-clinicemr-${IMAGE}:${IMAGE_TAG}"
        
        print_info "Processing ${IMAGE}..."
        
        # Tag the image
        docker tag "${LOCAL_IMAGE}" "${REMOTE_IMAGE}"
        if [ $? -ne 0 ]; then
            print_error "Failed to tag ${IMAGE}"
            continue
        fi
        
        # Push the image
        print_info "Pushing ${REMOTE_IMAGE}..."
        docker push "${REMOTE_IMAGE}"
        
        if [ $? -eq 0 ]; then
            print_success "Successfully pushed ${REMOTE_IMAGE}"
        else
            print_error "Failed to push ${REMOTE_IMAGE}"
        fi
        echo ""
    done
    
    print_success "Push operation completed!"
    print_info "Images pushed:"
    for IMAGE in "${IMAGES[@]}"; do
        echo "  - ${DOCKER_USERNAME}/openmrs-clinicemr-${IMAGE}:${IMAGE_TAG}"
    done
}

# Function to tag images with custom tag
tag_images() {
    local TAG=$1
    
    if [ -z "$TAG" ]; then
        print_error "Please specify a tag name."
        print_info "Usage: $0 tag <tag-name>"
        return 1
    fi
    
    cd "$SCRIPT_DIR"
    
    print_info "Enter your Docker Hub username or organization name:"
    read -p "Docker Hub username: " DOCKER_USERNAME
    
    if [ -z "$DOCKER_USERNAME" ]; then
        print_error "Username cannot be empty."
        return 1
    fi
    
    declare -a IMAGES=("gateway" "frontend" "backend")
    
    print_info "Tagging images with tag: ${TAG}..."
    echo ""
    
    for IMAGE in "${IMAGES[@]}"; do
        LOCAL_IMAGE="openmrs-03-distro-clinicemr-${IMAGE}"
        REMOTE_IMAGE="${DOCKER_USERNAME}/openmrs-clinicemr-${IMAGE}:${TAG}"
        
        print_info "Tagging ${IMAGE}..."
        docker tag "${LOCAL_IMAGE}" "${REMOTE_IMAGE}"
        
        if [ $? -eq 0 ]; then
            print_success "Tagged as ${REMOTE_IMAGE}"
        else
            print_error "Failed to tag ${IMAGE}"
        fi
    done
    
    echo ""
    print_success "Tagging completed!"
    print_info "To push these images, run: docker push ${DOCKER_USERNAME}/openmrs-clinicemr-<service>:${TAG}"
}

# Fallback polling mode for watch
watch_polling() {
    cd "$SCRIPT_DIR"
    
    # Initial build and start
    build_and_start
    
    # Store initial checksums
    local last_checksum=$(find . -name 'Dockerfile' -o -name 'docker-compose*.yml' | sort | xargs md5sum 2>/dev/null | md5sum)
    
    print_info "Polling for changes every 5 seconds..."
    
    while true; do
        sleep 5
        
        local current_checksum=$(find . -name 'Dockerfile' -o -name 'docker-compose*.yml' | sort | xargs md5sum 2>/dev/null | md5sum)
        
        if [ "$current_checksum" != "$last_checksum" ]; then
            print_warning "Changes detected! Rebuilding..."
            
            print_info "Stopping containers..."
            docker compose down
            
            print_info "Rebuilding and restarting..."
            build_and_start
            
            last_checksum=$current_checksum
            print_info "Waiting for next change..."
        fi
    done
}

# Function to open shell in container
open_shell() {
    local container=$1
    if [ -z "$container" ]; then
        print_error "Please specify a container: backend, frontend, gateway, or db"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
    case $container in
        backend|frontend|gateway|db)
            print_info "Opening shell in $container container..."
            docker compose exec "$container" /bin/sh
            ;;
        *)
            print_error "Invalid container. Choose: backend, frontend, gateway, or db"
            exit 1
            ;;
    esac
}

# Function to show interactive menu
show_menu() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         ClinicEMR - Docker Management Menu                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Basic Operations:${NC}"
    echo "  1) Build Docker images"
    echo "  2) Start containers"
    echo "  3) Stop containers"
    echo "  4) Restart containers"
    echo "  5) Rebuild (clean + build + start)"
    echo "  6) Build and start (build + start)"
    echo "  7) Development mode with hot reload 🔥"
    echo "  8) Watch mode (auto-rebuild on changes)"
    echo ""
    echo -e "${BLUE}Docker Hub Operations:${NC}"
    echo "  9) Build and push to Docker Hub"
    echo " 10) Tag images with custom tag"
    echo ""
    echo -e "${BLUE}Monitoring:${NC}"
    echo " 11) Show container status"
    echo " 12) View logs (last 100 lines)"
    echo " 13) Follow logs (real-time)"
    echo ""
    echo -e "${BLUE}SSL Operations:${NC}"
    echo " 14) Start with SSL"
    echo " 15) Stop SSL containers"
    echo ""
    echo -e "${BLUE}Shell Access:${NC}"
    echo " 16) Open shell in backend container"
    echo " 17) Open shell in frontend container"
    echo " 18) Open shell in gateway container"
    echo " 19) Open shell in database container"
    echo ""
    echo -e "${YELLOW}Cleanup Operations:${NC}"
    echo " 20) Clean containers (remove containers)"
    echo " 21) Clean volumes (⚠️  WARNING: deletes all data)"
    echo " 22) Clean all (⚠️  WARNING: removes everything)"
    echo ""
    echo -e "${BLUE}Other:${NC}"
    echo " 23) Show help/usage"
    echo "  0) Exit"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
}

# Function to handle menu selection
handle_selection() {
    local choice=$1
    
    case $choice in
        1)
            build_images
            ;;
        2)
            start_containers
            ;;
        3)
            stop_containers
            ;;
        4)
            restart_containers
            ;;
        5)
            rebuild
            ;;
        6)
            build_and_start
            ;;
        7)
            start_dev_with_logs
            ;;
        8)
            watch_and_rebuild
            ;;
        9)
            push_to_dockerhub
            ;;
        10)
            echo -n "Enter tag name: "
            read -r tag_name
            tag_images "$tag_name"
            ;;
        11)
            show_status
            ;;
        12)
            show_logs
            ;;
        13)
            show_logs "-f"
            ;;
        14)
            start_ssl
            ;;
        15)
            stop_ssl
            ;;
        16)
            open_shell "backend"
            ;;
        17)
            open_shell "frontend"
            ;;
        18)
            open_shell "gateway"
            ;;
        19)
            open_shell "db"
            ;;
        20)
            clean_containers
            ;;
        21)
            clean_volumes
            ;;
        22)
            clean_all
            ;;
        23)
            show_usage
            ;;
        0)
            print_info "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid option: $choice"
            ;;
    esac
}

# Interactive mode
interactive_mode() {
    while true; do
        show_menu
        echo -n "Enter your choice [0-23]: "
        read -r choice
        echo ""
        
        if [ "$choice" == "0" ]; then
            print_info "Goodbye!"
            exit 0
        fi
        
        handle_selection "$choice"
        
        echo ""
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
    done
}

# Main script logic
main() {
    # If no arguments, run interactive mode
    if [ $# -eq 0 ]; then
        interactive_mode
        exit 0
    fi

    # Command-line mode (backward compatible)
    case "$1" in
        build)
            build_images
            ;;
        start)
            start_containers
            ;;
        start-ssl)
            start_ssl
            ;;
        stop)
            stop_containers
            ;;
        stop-ssl)
            stop_ssl
            ;;
        restart)
            restart_containers
            ;;
        logs)
            show_logs "$2"
            ;;
        status)
            show_status
            ;;
        clean)
            clean_containers
            ;;
        clean-volumes)
            clean_volumes
            ;;
        clean-all)
            clean_all
            ;;
        rebuild)
            rebuild
            ;;
        build-start)
            build_and_start
            ;;
        dev)
            start_dev_mode
            ;;
        dev-logs)
            start_dev_with_logs
            ;;
        stop-dev)
            stop_dev_mode
            ;;
        watch)
            watch_and_rebuild
            ;;
        push)
            push_to_dockerhub
            ;;
        tag)
            tag_images "$2"
            ;;
        shell)
            open_shell "$2"
            ;;
        -h|--help)
            show_usage
            ;;
        -i|--interactive|menu)
            interactive_mode
            ;;
        *)
            print_error "Unknown command: $1"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

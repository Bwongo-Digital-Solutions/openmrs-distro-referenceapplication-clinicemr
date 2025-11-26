#!/usr/bin/env pwsh
# OpenMRS Docker Management Script for Windows PowerShell
# This script helps manage the OpenMRS Docker environment on Windows

# Enable strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Colors for output
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to build images
function Build-Images {
    Write-Info "Building Docker images..."
    docker compose build --no-cache
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Images built successfully!"
    } else {
        Write-Error "Build failed!"
        exit 1
    }
}

# Function to start containers
function Start-Containers {
    Write-Info "Starting containers..."
    docker compose up -d
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Containers started!"
        Write-Info "OpenMRS UI: http://localhost/openmrs/spa"
        Write-Info "Legacy UI: http://localhost/openmrs"
    } else {
        Write-Error "Failed to start containers!"
        exit 1
    }
}

# Function to stop containers
function Stop-Containers {
    Write-Info "Stopping containers..."
    docker compose down
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Containers stopped!"
    } else {
        Write-Error "Failed to stop containers!"
        exit 1
    }
}

# Function to restart containers
function Restart-Containers {
    Write-Info "Restarting containers..."
    Stop-Containers
    Start-Containers
}

# Function to show logs
function Show-Logs {
    param([string]$Follow)
    if ($Follow -eq "-f" -or $Follow -eq "--follow") {
        Write-Info "Following logs (Ctrl+C to exit)..."
        docker compose logs -f
    } else {
        docker compose logs --tail=100
    }
}

# Function to show status
function Show-Status {
    Write-Info "Container status:"
    docker compose ps
}

# Function to rebuild everything
function Rebuild-All {
    Write-Info "Rebuilding environment..."
    Clean-Containers
    Build-Images
    Start-Containers
}

# Function to build and start
function Build-AndStart {
    Write-Info "Building images and starting containers..."
    Build-Images
    Start-Containers
}

# Function to start development mode
function Start-DevMode {
    Write-Info "Starting development mode with hot reload..."
    
    if (-not (Test-Path "docker-compose.dev.yml")) {
        Write-Error "docker-compose.dev.yml not found!"
        Write-Info "Hot reload requires docker-compose.dev.yml"
        exit 1
    }
    
    Write-Info "Building development images..."
    docker compose -f docker-compose.yml -f docker-compose.dev.yml build
    
    Write-Info "Starting containers with volume mounts for hot reload..."
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Development mode started!"
        Write-Info "OpenMRS UI: http://localhost/openmrs/spa"
        Write-Info "Backend Debug Port: 1044"
        Write-Host ""
        Write-Host "Hot Reload Enabled:" -ForegroundColor Green
        Write-Info "  - Frontend configs: ./frontend/config-core_demo.json"
        Write-Info "  - Frontend assets: ./frontend/assets/"
        Write-Info "  - Backend config: ./distro/configuration/"
        Write-Host ""
        Write-Warning "Changes to these files will be reflected without rebuild!"
    } else {
        Write-Error "Failed to start dev mode!"
        exit 1
    }
}

# Function to start dev mode with logs
function Start-DevWithLogs {
    Start-DevMode
    Write-Host ""
    Write-Info "Following logs (Ctrl+C to exit)..."
    Start-Sleep -Seconds 2
    docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f
}

# Function to stop dev mode
function Stop-DevMode {
    Write-Info "Stopping development containers..."
    docker compose -f docker-compose.yml -f docker-compose.dev.yml down
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Development containers stopped!"
    } else {
        Write-Error "Failed to stop dev containers!"
        exit 1
    }
}

# Function to watch for changes (PowerShell version)
function Watch-AndRebuild {
    Write-Info "Starting watch mode..."
    Write-Info "Watching for changes in Dockerfiles and docker-compose files"
    Write-Warning "Press Ctrl+C to stop watching"
    Write-Host ""
    Write-Host "TIP: For hot reload without rebuild, use 'dev' mode instead!" -ForegroundColor Yellow
    Write-Host ""
    
    # Initial build and start
    Build-AndStart
    
    # Watch for changes
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = Get-Location
    $watcher.Filter = "*.*"
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true
    
    $changed = Register-ObjectEvent $watcher "Changed" -Action {
        $name = $Event.SourceEventArgs.Name
        if ($name -match "Dockerfile" -or $name -match "docker-compose.*\.yml") {
            Write-Warning "Changes detected in $name! Rebuilding..."
            Start-Sleep -Seconds 2
            
            Write-Info "Stopping containers..."
            docker compose down
            
            Write-Info "Rebuilding and restarting..."
            docker compose build --no-cache
            docker compose up -d
            
            Write-Info "Waiting for next change..."
        }
    }
    
    try {
        Write-Info "Watching for changes... (Press Ctrl+C to stop)"
        while ($true) {
            Start-Sleep -Seconds 1
        }
    } finally {
        Unregister-Event -SourceIdentifier $changed.Name
        $watcher.Dispose()
    }
}

# Function to push to Docker Hub
function Push-ToDockerHub {
    Write-Info "Building and pushing images to Docker Hub..."
    Write-Host ""
    
    # Check if logged in
    $dockerInfo = docker info 2>&1 | Out-String
    if ($dockerInfo -notmatch "Username") {
        Write-Warning "You are not logged in to Docker Hub."
        $login = Read-Host "Do you want to login now? (y/N)"
        if ($login -eq "y" -or $login -eq "Y") {
            docker login
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Docker login failed. Aborting push."
                exit 1
            }
        } else {
            Write-Error "Cannot push without Docker Hub authentication."
            exit 1
        }
    }
    
    $username = Read-Host "Enter your Docker Hub username"
    if ([string]::IsNullOrEmpty($username)) {
        Write-Error "Username cannot be empty."
        exit 1
    }
    
    $tag = Read-Host "Enter tag for images (default: latest)"
    if ([string]::IsNullOrEmpty($tag)) {
        $tag = "latest"
    }
    
    Write-Info "Building images..."
    docker compose build --no-cache
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed. Aborting push."
        exit 1
    }
    
    $images = @("gateway", "frontend", "backend")
    
    Write-Info "Tagging and pushing images..."
    Write-Host ""
    
    foreach ($image in $images) {
        $localImage = "openmrs-03-distro-clinicemr-$image"
        $remoteImage = "$username/openmrs-clinicemr-${image}:$tag"
        
        Write-Info "Processing $image..."
        
        docker tag $localImage $remoteImage
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to tag $image"
            continue
        }
        
        Write-Info "Pushing $remoteImage..."
        docker push $remoteImage
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Successfully pushed $remoteImage"
        } else {
            Write-Error "Failed to push $remoteImage"
        }
        Write-Host ""
    }
    
    Write-Success "Push operation completed!"
}

# Function to tag images
function Tag-Images {
    param([string]$Tag)
    
    if ([string]::IsNullOrEmpty($Tag)) {
        Write-Error "Please specify a tag name."
        Write-Info "Usage: .\manage.ps1 tag <tag-name>"
        exit 1
    }
    
    $username = Read-Host "Enter your Docker Hub username"
    if ([string]::IsNullOrEmpty($username)) {
        Write-Error "Username cannot be empty."
        exit 1
    }
    
    $images = @("gateway", "frontend", "backend")
    
    Write-Info "Tagging images with tag: $Tag..."
    Write-Host ""
    
    foreach ($image in $images) {
        $localImage = "openmrs-03-distro-clinicemr-$image"
        $remoteImage = "$username/openmrs-clinicemr-${image}:$Tag"
        
        Write-Info "Tagging $image..."
        docker tag $localImage $remoteImage
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Tagged as $remoteImage"
        } else {
            Write-Error "Failed to tag $image"
        }
    }
    
    Write-Host ""
    Write-Success "Tagging completed!"
}

# Function to start with SSL
function Start-SSL {
    Write-Info "Starting containers with SSL..."
    docker compose -f docker-compose.yml -f docker-compose.ssl.yml up -d
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Containers started with SSL!"
        Write-Info "OpenMRS UI: https://localhost/openmrs/spa"
        Write-Info "Legacy UI: https://localhost/openmrs"
        Write-Warning "If using self-signed certificates, your browser will show a security warning."
    } else {
        Write-Error "Failed to start SSL containers!"
        exit 1
    }
}

# Function to stop SSL
function Stop-SSL {
    Write-Info "Stopping SSL containers..."
    docker compose -f docker-compose.yml -f docker-compose.ssl.yml down
    if ($LASTEXITCODE -eq 0) {
        Write-Success "SSL containers stopped!"
    } else {
        Write-Error "Failed to stop SSL containers!"
        exit 1
    }
}

# Function to clean containers
function Clean-Containers {
    Write-Warning "This will stop and remove all containers."
    $confirm = Read-Host "Are you sure? (y/N)"
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        Write-Info "Cleaning containers..."
        docker compose down
        Write-Success "Containers removed!"
    } else {
        Write-Info "Cancelled."
    }
}

# Function to clean volumes
function Clean-Volumes {
    Write-Error "WARNING: This will delete all data including the database!"
    $confirm = Read-Host "Type 'yes' to confirm"
    if ($confirm -eq "yes") {
        Write-Info "Removing volumes..."
        docker compose down -v
        Write-Success "Volumes removed!"
    } else {
        Write-Info "Cancelled."
    }
}

# Function to clean all
function Clean-All {
    Write-Error "WARNING: This will remove containers, volumes, and images!"
    Write-Error "All data will be lost and images will need to be rebuilt!"
    $confirm = Read-Host "Type 'DELETE' to confirm"
    if ($confirm -eq "DELETE") {
        Write-Info "Removing all resources..."
        docker compose down -v
        docker compose down --rmi all
        docker system prune -f
        Write-Success "All resources removed!"
    } else {
        Write-Info "Cancelled."
    }
}

# Function to open shell
function Open-Shell {
    param([string]$Container)
    
    if ([string]::IsNullOrEmpty($Container)) {
        Write-Error "Please specify a container: backend, frontend, gateway, or db"
        exit 1
    }
    
    Write-Info "Opening shell in $Container container..."
    docker compose exec $Container /bin/sh
}

# Function to show usage
function Show-Usage {
    Write-Host @"

====================================================================
         ClinicEMR - Docker Management Script (PowerShell)
====================================================================

Interactive Mode:
    .\manage.ps1                Run without arguments for interactive menu
    .\manage.ps1 menu           Explicitly launch interactive menu
    .\manage.ps1 -i             Same as above

Command-Line Mode:

Basic Commands:
    build           Build all Docker images
    start           Start all containers
    stop            Stop all containers
    restart         Restart all containers
    logs            Show logs (use -f to follow)
    status          Show status of all containers
    rebuild         Clean, build and start containers
    build-start     Build images and start containers
    dev             Start in development mode with hot reload
    dev-logs        Start dev mode and follow logs
    stop-dev        Stop development containers
    watch           Watch for changes and rebuild automatically

Docker Hub Commands:
    push            Build and push images to Docker Hub
    tag <name>      Tag images with custom tag

SSL Commands:
    start-ssl       Start with SSL enabled
    stop-ssl        Stop SSL-enabled containers

Cleanup Commands:
    clean           Stop and remove all containers
    clean-volumes   Remove all volumes (WARNING: data loss)
    clean-all       Stop containers, remove volumes and images

Shell Access:
    shell <name>    Open shell in container (backend, frontend, gateway, db)

Options:
    -h, -help       Show this help message

Examples:
    .\manage.ps1                # Interactive menu
    .\manage.ps1 build          # Build all images
    .\manage.ps1 start          # Start containers
    .\manage.ps1 dev            # Start with hot reload
    .\manage.ps1 watch          # Watch for changes
    .\manage.ps1 logs -f        # Follow logs
    .\manage.ps1 shell backend  # Open shell in backend

"@
}

# Function to show interactive menu
function Show-Menu {
    Clear-Host
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host "         ClinicEMR - Docker Management Menu (PowerShell)           " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Basic Operations:" -ForegroundColor Cyan
    Write-Host "  1) Build Docker images"
    Write-Host "  2) Start containers"
    Write-Host "  3) Stop containers"
    Write-Host "  4) Restart containers"
    Write-Host "  5) Rebuild (clean + build + start)"
    Write-Host "  6) Build and start"
    Write-Host "  7) Development mode with hot reload 🔥"
    Write-Host "  8) Watch mode (auto-rebuild on changes)"
    Write-Host ""
    Write-Host "Docker Hub Operations:" -ForegroundColor Cyan
    Write-Host "  9) Build and push to Docker Hub"
    Write-Host " 10) Tag images with custom tag"
    Write-Host ""
    Write-Host "Monitoring:" -ForegroundColor Cyan
    Write-Host " 11) Show container status"
    Write-Host " 12) View logs (last 100 lines)"
    Write-Host " 13) Follow logs (real-time)"
    Write-Host ""
    Write-Host "SSL Operations:" -ForegroundColor Cyan
    Write-Host " 14) Start with SSL"
    Write-Host " 15) Stop SSL containers"
    Write-Host ""
    Write-Host "Shell Access:" -ForegroundColor Cyan
    Write-Host " 16) Open shell in backend container"
    Write-Host " 17) Open shell in frontend container"
    Write-Host " 18) Open shell in gateway container"
    Write-Host " 19) Open shell in database container"
    Write-Host ""
    Write-Host "Cleanup Operations:" -ForegroundColor Yellow
    Write-Host " 20) Clean containers"
    Write-Host " 21) Clean volumes (⚠️  WARNING: data loss)"
    Write-Host " 22) Clean all (⚠️  WARNING: removes everything)"
    Write-Host ""
    Write-Host "Other:" -ForegroundColor Cyan
    Write-Host " 23) Show help/usage"
    Write-Host "  0) Exit"
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Green
}

# Function to handle menu selection
function Handle-Selection {
    param([string]$Choice)
    
    switch ($Choice) {
        "1" { Build-Images }
        "2" { Start-Containers }
        "3" { Stop-Containers }
        "4" { Restart-Containers }
        "5" { Rebuild-All }
        "6" { Build-AndStart }
        "7" { Start-DevWithLogs }
        "8" { Watch-AndRebuild }
        "9" { Push-ToDockerHub }
        "10" {
            $tag = Read-Host "Enter tag name"
            Tag-Images $tag
        }
        "11" { Show-Status }
        "12" { Show-Logs }
        "13" { Show-Logs "-f" }
        "14" { Start-SSL }
        "15" { Stop-SSL }
        "16" { Open-Shell "backend" }
        "17" { Open-Shell "frontend" }
        "18" { Open-Shell "gateway" }
        "19" { Open-Shell "db" }
        "20" { Clean-Containers }
        "21" { Clean-Volumes }
        "22" { Clean-All }
        "23" { Show-Usage }
        "0" {
            Write-Info "Goodbye!"
            exit 0
        }
        default { Write-Error "Invalid option: $Choice" }
    }
}

# Interactive mode
function Interactive-Mode {
    while ($true) {
        Show-Menu
        $choice = Read-Host "Enter your choice [0-23]"
        Write-Host ""
        
        if ($choice -eq "0") {
            Write-Info "Goodbye!"
            exit 0
        }
        
        Handle-Selection $choice
        
        Write-Host ""
        Write-Host "Press any key to continue..." -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Main script logic
if ($args.Count -eq 0) {
    Interactive-Mode
} else {
    $command = $args[0]
    
    switch ($command) {
        "build" { Build-Images }
        "start" { Start-Containers }
        "stop" { Stop-Containers }
        "restart" { Restart-Containers }
        "logs" { Show-Logs $args[1] }
        "status" { Show-Status }
        "rebuild" { Rebuild-All }
        "build-start" { Build-AndStart }
        "dev" { Start-DevMode }
        "dev-logs" { Start-DevWithLogs }
        "stop-dev" { Stop-DevMode }
        "watch" { Watch-AndRebuild }
        "push" { Push-ToDockerHub }
        "tag" { Tag-Images $args[1] }
        "start-ssl" { Start-SSL }
        "stop-ssl" { Stop-SSL }
        "clean" { Clean-Containers }
        "clean-volumes" { Clean-Volumes }
        "clean-all" { Clean-All }
        "shell" { Open-Shell $args[1] }
        {$_ -in "-h", "--help", "help"} { Show-Usage }
        {$_ -in "-i", "--interactive", "menu"} { Interactive-Mode }
        default {
            Write-Error "Unknown command: $command"
            Write-Host ""
            Show-Usage
            exit 1
        }
    }
}

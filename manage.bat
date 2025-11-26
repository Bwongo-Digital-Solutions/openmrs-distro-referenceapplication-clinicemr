@echo off
REM ClinicEMR Docker Management Script for Windows
REM This script helps manage the ClinicEMR Docker environment on Windows

setlocal enabledelayedexpansion

REM Colors using PowerShell
set "INFO=[INFO]"
set "SUCCESS=[SUCCESS]"
set "WARNING=[WARNING]"
set "ERROR=[ERROR]"

:main
if "%1"=="" goto interactive_mode
if /i "%1"=="menu" goto interactive_mode
if /i "%1"=="-i" goto interactive_mode
goto command_mode

:command_mode
if /i "%1"=="build" goto build
if /i "%1"=="start" goto start
if /i "%1"=="stop" goto stop
if /i "%1"=="restart" goto restart
if /i "%1"=="logs" goto logs
if /i "%1"=="status" goto status
if /i "%1"=="rebuild" goto rebuild
if /i "%1"=="build-start" goto build_start
if /i "%1"=="dev" goto dev
if /i "%1"=="dev-logs" goto dev_logs
if /i "%1"=="stop-dev" goto stop_dev
if /i "%1"=="watch" goto watch
if /i "%1"=="push" goto push
if /i "%1"=="tag" goto tag
if /i "%1"=="start-ssl" goto start_ssl
if /i "%1"=="stop-ssl" goto stop_ssl
if /i "%1"=="clean" goto clean
if /i "%1"=="clean-volumes" goto clean_volumes
if /i "%1"=="clean-all" goto clean_all
if /i "%1"=="shell" goto shell
if /i "%1"=="-h" goto usage
if /i "%1"=="--help" goto usage
echo %ERROR% Unknown command: %1
echo.
goto usage

:build
echo %INFO% Building Docker images...
docker compose build --no-cache
if %errorlevel% equ 0 (
    echo %SUCCESS% Images built successfully!
) else (
    echo %ERROR% Build failed!
    exit /b 1
)
goto end

:start
echo %INFO% Starting containers...
docker compose up -d
if %errorlevel% equ 0 (
    echo %SUCCESS% Containers started!
    echo %INFO% ClinicEMR UI: http://localhost/openmrs/spa
    echo %INFO% Legacy UI: http://localhost/openmrs
) else (
    echo %ERROR% Failed to start containers!
    exit /b 1
)
goto end

:stop
echo %INFO% Stopping containers...
docker compose down
if %errorlevel% equ 0 (
    echo %SUCCESS% Containers stopped!
) else (
    echo %ERROR% Failed to stop containers!
    exit /b 1
)
goto end

:restart
echo %INFO% Restarting containers...
call :stop
call :start
goto end

:logs
echo %INFO% Showing logs...
if /i "%2"=="-f" (
    docker compose logs -f
) else if /i "%2"=="--follow" (
    docker compose logs -f
) else (
    docker compose logs --tail=100
)
goto end

:status
echo %INFO% Container status:
docker compose ps
goto end

:rebuild
echo %INFO% Rebuilding environment...
call :clean
call :build
call :start
goto end

:build_start
echo %INFO% Building images and starting containers...
call :build
call :start
goto end

:dev
echo %INFO% Starting development mode with hot reload...
if not exist "docker-compose.dev.yml" (
    echo %ERROR% docker-compose.dev.yml not found!
    echo %INFO% Hot reload requires docker-compose.dev.yml
    exit /b 1
)
echo %INFO% Building development images...
docker compose -f docker-compose.yml -f docker-compose.dev.yml build
echo %INFO% Starting containers with volume mounts for hot reload...
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
if %errorlevel% equ 0 (
    echo %SUCCESS% Development mode started!
    echo %INFO% OpenMRS UI: http://localhost/openmrs/spa
    echo %INFO% Backend Debug Port: 1044
    echo.
    echo %INFO% Hot Reload Enabled:
    echo %INFO%   - Frontend configs: ./frontend/config-core_demo.json
    echo %INFO%   - Frontend assets: ./frontend/assets/
    echo %INFO%   - Backend config: ./distro/configuration/
    echo.
    echo %WARNING% Changes to these files will be reflected without rebuild!
) else (
    echo %ERROR% Failed to start dev mode!
    exit /b 1
)
goto end

:dev_logs
call :dev
echo.
echo %INFO% Following logs (Ctrl+C to exit)...
timeout /t 2 /nobreak >nul
docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f
goto end

:stop_dev
echo %INFO% Stopping development containers...
docker compose -f docker-compose.yml -f docker-compose.dev.yml down
if %errorlevel% equ 0 (
    echo %SUCCESS% Development containers stopped!
) else (
    echo %ERROR% Failed to stop dev containers!
    exit /b 1
)
goto end

:watch
echo %WARNING% Watch mode requires manual implementation on Windows
echo %INFO% Suggested alternatives:
echo %INFO%   1. Use 'dev' mode for hot reload without rebuild
echo %INFO%   2. Use PowerShell script (manage.ps1) for better watch support
echo %INFO%   3. Use WSL2 with the Linux manage.sh script
goto end

:push
echo %INFO% Building and pushing images to Docker Hub...
echo.
set /p DOCKER_USERNAME="Enter Docker Hub username: "
if "!DOCKER_USERNAME!"=="" (
    echo %ERROR% Username cannot be empty!
    exit /b 1
)
set /p IMAGE_TAG="Enter tag (default: latest): "
if "!IMAGE_TAG!"=="" set IMAGE_TAG=latest

echo %INFO% Building images...
docker compose build --no-cache
if %errorlevel% neq 0 (
    echo %ERROR% Build failed!
    exit /b 1
)

echo %INFO% Tagging and pushing images...
for %%i in (gateway frontend backend) do (
    echo %INFO% Processing %%i...
    docker tag openmrs-03-distro-clinicemr-%%i !DOCKER_USERNAME!/openmrs-clinicemr-%%i:!IMAGE_TAG!
    docker push !DOCKER_USERNAME!/openmrs-clinicemr-%%i:!IMAGE_TAG!
    if !errorlevel! equ 0 (
        echo %SUCCESS% Pushed !DOCKER_USERNAME!/openmrs-clinicemr-%%i:!IMAGE_TAG!
    ) else (
        echo %ERROR% Failed to push %%i
    )
)
goto end

:tag
if "%2"=="" (
    echo %ERROR% Please specify a tag name
    echo %INFO% Usage: manage.bat tag ^<tag-name^>
    exit /b 1
)
set /p DOCKER_USERNAME="Enter Docker Hub username: "
if "!DOCKER_USERNAME!"=="" (
    echo %ERROR% Username cannot be empty!
    exit /b 1
)
for %%i in (gateway frontend backend) do (
    echo %INFO% Tagging %%i...
    docker tag openmrs-03-distro-clinicemr-%%i !DOCKER_USERNAME!/openmrs-clinicemr-%%i:%2
    if !errorlevel! equ 0 (
        echo %SUCCESS% Tagged as !DOCKER_USERNAME!/openmrs-clinicemr-%%i:%2
    ) else (
        echo %ERROR% Failed to tag %%i
    )
)
goto end

:start_ssl
echo %INFO% Starting containers with SSL...
docker compose -f docker-compose.yml -f docker-compose.ssl.yml up -d
if %errorlevel% equ 0 (
    echo %SUCCESS% Containers started with SSL!
    echo %INFO% OpenMRS UI: https://localhost/openmrs/spa
    echo %INFO% Legacy UI: https://localhost/openmrs
    echo %WARNING% If using self-signed certificates, your browser will show a security warning.
) else (
    echo %ERROR% Failed to start SSL containers!
    exit /b 1
)
goto end

:stop_ssl
echo %INFO% Stopping SSL containers...
docker compose -f docker-compose.yml -f docker-compose.ssl.yml down
if %errorlevel% equ 0 (
    echo %SUCCESS% SSL containers stopped!
) else (
    echo %ERROR% Failed to stop SSL containers!
    exit /b 1
)
goto end

:clean
echo %WARNING% This will stop and remove all containers.
set /p CONFIRM="Are you sure? (y/N): "
if /i "!CONFIRM!"=="y" (
    echo %INFO% Cleaning containers...
    docker compose down
    echo %SUCCESS% Containers removed!
) else (
    echo %INFO% Cancelled.
)
goto end

:clean_volumes
echo %ERROR% WARNING: This will delete all data including the database!
set /p CONFIRM="Type 'yes' to confirm: "
if "!CONFIRM!"=="yes" (
    echo %INFO% Removing volumes...
    docker compose down -v
    echo %SUCCESS% Volumes removed!
) else (
    echo %INFO% Cancelled.
)
goto end

:clean_all
echo %ERROR% WARNING: This will remove containers, volumes, and images!
echo %ERROR% All data will be lost and images will need to be rebuilt!
set /p CONFIRM="Type 'DELETE' to confirm: "
if "!CONFIRM!"=="DELETE" (
    echo %INFO% Removing all resources...
    docker compose down -v
    docker compose down --rmi all
    docker system prune -f
    echo %SUCCESS% All resources removed!
) else (
    echo %INFO% Cancelled.
)
goto end

:shell
if "%2"=="" (
    echo %ERROR% Please specify a container: backend, frontend, gateway, or db
    exit /b 1
)
echo %INFO% Opening shell in %2 container...
docker compose exec %2 /bin/sh
goto end

:usage
echo.
echo ====================================================================
echo            ClinicEMR - Docker Management Script (Windows)
echo ====================================================================
echo.
echo Interactive Mode:
echo     manage.bat                  Run without arguments for interactive menu
echo     manage.bat menu             Explicitly launch interactive menu
echo     manage.bat -i               Same as above
echo.
echo Command-Line Mode:
echo.
echo Basic Commands:
echo     build           Build all Docker images
echo     start           Start all containers
echo     stop            Stop all containers
echo     restart         Restart all containers
echo     logs            Show logs (use -f to follow)
echo     status          Show status of all containers
echo     rebuild         Clean, build and start containers
echo     build-start     Build images and start containers
echo     dev             Start in development mode with hot reload
echo     dev-logs        Start dev mode and follow logs
echo     stop-dev        Stop development containers
echo.
echo Docker Hub Commands:
echo     push            Build and push images to Docker Hub
echo     tag ^<name^>      Tag images with custom tag
echo.
echo SSL Commands:
echo     start-ssl       Start with SSL enabled
echo     stop-ssl        Stop SSL-enabled containers
echo.
echo Cleanup Commands:
echo     clean           Stop and remove all containers
echo     clean-volumes   Remove all volumes (WARNING: data loss)
echo     clean-all       Stop containers, remove volumes and images
echo.
echo Shell Access:
echo     shell ^<name^>    Open shell in container (backend, frontend, gateway, db)
echo.
echo Options:
echo     -h, --help      Show this help message
echo.
echo Examples:
echo     manage.bat                  # Interactive menu
echo     manage.bat build            # Build all images
echo     manage.bat start            # Start containers
echo     manage.bat dev              # Start with hot reload
echo     manage.bat logs -f          # Follow logs
echo     manage.bat shell backend    # Open shell in backend
echo.
goto end

:interactive_mode
cls
echo ====================================================================
echo            ClinicEMR - Docker Management Menu (Windows)
echo ====================================================================
echo.
echo Basic Operations:
echo   1) Build Docker images
echo   2) Start containers
echo   3) Stop containers
echo   4) Restart containers
echo   5) Rebuild (clean + build + start)
echo   6) Build and start
echo   7) Development mode with hot reload
echo   8) Stop dev containers
echo.
echo Docker Hub Operations:
echo   9) Build and push to Docker Hub
echo  10) Tag images with custom tag
echo.
echo Monitoring:
echo  11) Show container status
echo  12) View logs (last 100 lines)
echo  13) Follow logs (real-time)
echo.
echo SSL Operations:
echo  14) Start with SSL
echo  15) Stop SSL containers
echo.
echo Shell Access:
echo  16) Open shell in backend container
echo  17) Open shell in frontend container
echo  18) Open shell in gateway container
echo  19) Open shell in database container
echo.
echo Cleanup Operations:
echo  20) Clean containers
echo  21) Clean volumes (WARNING: data loss)
echo  22) Clean all (WARNING: removes everything)
echo.
echo Other:
echo  23) Show help/usage
echo   0) Exit
echo.
echo ====================================================================
set /p choice="Enter your choice [0-23]: "

if "%choice%"=="0" goto exit
if "%choice%"=="1" call :build & goto continue
if "%choice%"=="2" call :start & goto continue
if "%choice%"=="3" call :stop & goto continue
if "%choice%"=="4" call :restart & goto continue
if "%choice%"=="5" call :rebuild & goto continue
if "%choice%"=="6" call :build_start & goto continue
if "%choice%"=="7" call :dev_logs & goto continue
if "%choice%"=="8" call :stop_dev & goto continue
if "%choice%"=="9" call :push & goto continue
if "%choice%"=="10" (
    set /p tag_name="Enter tag name: "
    call :tag !tag_name!
    goto continue
)
if "%choice%"=="11" call :status & goto continue
if "%choice%"=="12" call :logs & goto continue
if "%choice%"=="13" call :logs -f & goto continue
if "%choice%"=="14" call :start_ssl & goto continue
if "%choice%"=="15" call :stop_ssl & goto continue
if "%choice%"=="16" call :shell backend & goto continue
if "%choice%"=="17" call :shell frontend & goto continue
if "%choice%"=="18" call :shell gateway & goto continue
if "%choice%"=="19" call :shell db & goto continue
if "%choice%"=="20" call :clean & goto continue
if "%choice%"=="21" call :clean_volumes & goto continue
if "%choice%"=="22" call :clean_all & goto continue
if "%choice%"=="23" call :usage & goto continue

echo %ERROR% Invalid option: %choice%

:continue
echo.
echo Press any key to continue...
pause >nul
goto interactive_mode

:exit
echo %INFO% Goodbye!
exit /b 0

:end
endlocal

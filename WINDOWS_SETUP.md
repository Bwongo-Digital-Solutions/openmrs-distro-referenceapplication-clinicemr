# Windows Setup Guide

Quick guide for running OpenMRS ClinicEMR on Windows.

## 🪟 Prerequisites

1. **Docker Desktop for Windows** installed and running
2. **PowerShell 5.1+** or **Command Prompt**
3. **Git** (optional, for cloning repository)

## 🚀 Quick Start

### Option 1: PowerShell (Recommended)

Open PowerShell in the project directory and run:

```powershell
# Interactive menu
.\manage.ps1

# Or use direct commands
.\manage.ps1 build-start     # Build and start
.\manage.ps1 dev             # Development mode with hot reload
```

**First Time?** You may need to enable script execution:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Option 2: Command Prompt (CMD)

Open Command Prompt in the project directory:

```cmd
REM Interactive menu
manage.bat

REM Or use direct commands
manage.bat build-start       REM Build and start
manage.bat dev               REM Development mode with hot reload
```

### Option 3: WSL2 (Advanced)

If you have WSL2 installed:

```bash
wsl
./manage.sh build-start
```

## 📋 Available Commands

### PowerShell Commands
```powershell
.\manage.ps1 build           # Build Docker images
.\manage.ps1 start           # Start containers
.\manage.ps1 stop            # Stop containers
.\manage.ps1 dev             # Start with hot reload 🔥
.\manage.ps1 dev-logs        # Start dev mode + show logs
.\manage.ps1 stop-dev        # Stop dev mode
.\manage.ps1 status          # Show container status
.\manage.ps1 logs            # View logs
.\manage.ps1 logs -f         # Follow logs
.\manage.ps1 clean           # Remove containers
.\manage.ps1 shell backend   # Open shell in backend
```

### Batch (CMD) Commands
```cmd
manage.bat build             REM Build Docker images
manage.bat start             REM Start containers
manage.bat stop              REM Stop containers
manage.bat dev               REM Start with hot reload 🔥
manage.bat dev-logs          REM Start dev mode + show logs
manage.bat stop-dev          REM Stop dev mode
manage.bat status            REM Show container status
manage.bat logs              REM View logs
manage.bat clean             REM Remove containers
manage.bat shell backend     REM Open shell in backend
```

## 🔥 Hot Reload Development

Start development mode to enable instant config updates without rebuilding:

```powershell
# PowerShell
.\manage.ps1 dev-logs

# CMD
manage.bat dev-logs
```

Now you can edit these files and see changes instantly:
- `frontend\config-core_demo.json` - Frontend configuration
- `frontend\assets\logo.svg` - Logo and images
- `distro\configuration\` - Backend configuration

Just save the file and refresh your browser!

## 🌐 Accessing the Application

After starting containers:

- **OpenMRS SPA**: http://localhost/openmrs/spa
- **Legacy UI**: http://localhost/openmrs

**Default Credentials:**
- Username: `admin`
- Password: `Admin123`

## 🛠️ Common Tasks

### Change Logo

1. Replace `frontend\assets\logo.svg` with your logo
2. If running: Refresh browser (Ctrl+Shift+R)
3. If not running: Rebuild and start

```powershell
# If containers are running
.\manage.ps1 restart

# If using dev mode (no rebuild needed!)
# Just refresh browser
```

### Modify Frontend Config

```powershell
# Start dev mode
.\manage.ps1 dev

# Edit frontend\config-core_demo.json
# Save and refresh browser - changes appear instantly!
```

### View Logs

```powershell
# View recent logs
.\manage.ps1 logs

# Follow logs in real-time
.\manage.ps1 logs -f

# View specific service logs
docker compose logs frontend
docker compose logs backend
```

### Rebuild Everything

```powershell
.\manage.ps1 rebuild
```

## 🐛 Troubleshooting

### Docker Desktop Not Running

**Error:** `Cannot connect to the Docker daemon`

**Solution:** 
1. Open Docker Desktop
2. Wait for it to fully start (icon in system tray)
3. Try command again

### Port Already in Use

**Error:** `Bind for 0.0.0.0:80 failed: port is already allocated`

**Solution:**
```powershell
# Find what's using port 80
Get-NetTCPConnection -LocalPort 80

# Stop the process or change port in docker-compose.yml
```

### Permission Errors

**Error:** `cannot be loaded because running scripts is disabled`

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Changes Not Showing

1. Clear browser cache: `Ctrl + Shift + R`
2. Check if dev mode is running: `docker compose ps`
3. Restart dev mode:
   ```powershell
   .\manage.ps1 stop-dev
   .\manage.ps1 dev
   ```

### Container Fails to Start

```powershell
# Check logs
.\manage.ps1 logs

# Clean and rebuild
.\manage.ps1 clean
.\manage.ps1 build-start
```

## 📁 File Paths on Windows

Remember to use backslashes `\` when referring to paths:

```
✅ Correct:   frontend\config-core_demo.json
❌ Incorrect: frontend/config-core_demo.json (works in PowerShell but not CMD)
```

PowerShell accepts both `/` and `\`, but CMD only accepts `\`.

## 🔍 Check What's Running

```powershell
# Show all containers
docker compose ps

# Show container details
docker ps

# Show images
docker images
```

## 🧹 Cleanup

### Remove Containers Only
```powershell
.\manage.ps1 clean
```

### Remove Everything (including data)
```powershell
.\manage.ps1 clean-all
```

**⚠️ WARNING:** `clean-all` deletes all data including the database!

## 📚 Additional Help

- **Interactive Menu**: Just run `.\manage.ps1` or `manage.bat` without arguments
- **Full Documentation**: See `HOT_RELOAD_GUIDE.md`
- **Customization**: See `CUSTOMIZATION.md`

## 💡 Tips for Windows Users

1. **Use PowerShell**: Better colors and features than CMD
2. **Windows Terminal**: Install from Microsoft Store for best experience
3. **WSL2**: Consider using WSL2 for Linux-like experience
4. **Line Endings**: Git may convert line endings - use `.gitattributes`
5. **Paths**: Use Tab completion to avoid typos in paths

## 🎯 Quick Reference

| Task | PowerShell | CMD |
|------|-----------|-----|
| Start everything | `.\manage.ps1 build-start` | `manage.bat build-start` |
| Dev mode | `.\manage.ps1 dev` | `manage.bat dev` |
| Stop all | `.\manage.ps1 stop` | `manage.bat stop` |
| View logs | `.\manage.ps1 logs -f` | `manage.bat logs -f` |
| Interactive | `.\manage.ps1` | `manage.bat` |

## 🆘 Getting Help

```powershell
# Show help
.\manage.ps1 --help

# Or
.\manage.ps1 -h
```

---

**Need more help?** Check the `HOT_RELOAD_GUIDE.md` for detailed information!

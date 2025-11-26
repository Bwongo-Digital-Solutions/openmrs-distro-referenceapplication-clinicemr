# Custom Assets Directory

## Current Logos

✅ **ClinicEMR Logo** - Dual logo system configured!

### Colored Logo (`logo.svg`)
- Used on: **Login screen** and white backgrounds
- Colors: Vibrant blue (#2738F5) with cardiogram/ECG icon
- Features: "Medical Records System" subtitle, heartbeat waveform, transparent background

### White Logo (`logo-white.svg`)
- Used on: **Navigation bar** and colored backgrounds
- Colors: White (#FFFFFF) with cardiogram/ECG icon
- Features: Same design, optimized for visibility on colored backgrounds

This dual-logo approach ensures the logo is always visible and professional regardless of background color.

## Replacing the Logos

To use your own logos instead:

### Option 1: Replace Both Logos (Recommended)

1. **Create your logo variants**:
   - Colored version for white backgrounds
   - White version for colored backgrounds

2. **Replace the files**:
   ```bash
   # Colored logo (for login/white backgrounds)
   cp /path/to/your/logo-colored.svg logo.svg
   
   # White logo (for navbar/colored backgrounds)
   cp /path/to/your/logo-white.svg logo-white.svg
   ```

3. **If using hot reload** (changes apply immediately):
   ```bash
   # Just refresh your browser (Ctrl+Shift+R to clear cache)
   ```

4. **If not using hot reload**:
   ```bash
   cd ../..
   ./manage.sh rebuild
   ```

### Option 2: Single Logo Only

If you only want one logo for all contexts:

1. **Replace both files with the same logo**:
   ```bash
   cp /path/to/your/logo.svg logo.svg
   cp /path/to/your/logo.svg logo-white.svg
   ```

2. **Ensure your logo works on both light and dark backgrounds**
   - Use a neutral color scheme, OR
   - Add a background/stroke to ensure visibility

### Logo Requirements:
- **Format**: SVG (preferred) or PNG
- **Recommended size**: 300x80 pixels (or similar aspect ratio)
- **Background**: White or transparent
- **Filename**: `logo.svg` or `logo.png`

## Additional Assets

You can place other branding assets here:
- `favicon.ico` - Browser favicon
- `logo-dark.png` - Dark mode logo variant
- Other images or branding materials

All files in this directory will be copied to the frontend container at `/usr/share/nginx/html/`.

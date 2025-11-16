@echo off
echo Building Flutter web app...
flutter build web --release

if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit /b %errorlevel%
)

echo Copying Vercel config...
copy vercel.json build\web\vercel.json /Y >nul 2>&1
xcopy .vercel build\web\.vercel\ /E /I /Y /Q >nul 2>&1

echo Deploying to Vercel from project root...
vercel --prod --yes

echo.
echo ✅ Deployment complete!
echo Visit: https://campita.vercel.app
pause

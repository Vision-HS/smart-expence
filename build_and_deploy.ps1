$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"
$env:ANDROID_HOME = "D:\Android\sdk"
$env:PATH = "D:\flutter\bin;D:\Android\sdk\platform-tools;D:\Android\sdk\cmdline-tools\latest\bin;$env:JAVA_HOME\bin;$env:PATH"

Set-Location "d:\smart_expense\smart_expense"

Write-Host "Building Debug APK for Android (arm64)..."
& D:\flutter\bin\flutter.bat build apk --debug --split-per-abi

$apkPath = "build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk"
if (Test-Path $apkPath) {
    Write-Host "APK build successful! Installing onto Samsung phone (RZCX31PF4QV)..."
    $installRes = & D:\Android\sdk\platform-tools\adb.exe -s RZCX31PF4QV install -r $apkPath 2>&1
    Write-Host $installRes
    if ($installRes -match "Failure|INSTALL_FAILED") {
        Write-Host "Reinstall failed, trying fresh reinstall after uninstalling..."
        & D:\Android\sdk\platform-tools\adb.exe -s RZCX31PF4QV uninstall com.example.smart_expense
        & D:\Android\sdk\platform-tools\adb.exe -s RZCX31PF4QV install $apkPath
    }

    Write-Host "Launching Smart Expense app on phone..."
    & D:\Android\sdk\platform-tools\adb.exe -s RZCX31PF4QV shell am start -n com.example.smart_expense/.MainActivity

    Write-Host "Checking process status on phone..."
    & D:\Android\sdk\platform-tools\adb.exe -s RZCX31PF4QV shell pidof com.example.smart_expense
} else {
    Write-Error "APK was not found at $apkPath"
}

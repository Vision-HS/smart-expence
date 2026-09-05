$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"
$env:ANDROID_HOME = "D:\Android\sdk"
$env:PATH = "D:\flutter\bin;D:\Android\sdk\platform-tools;D:\Android\sdk\cmdline-tools\latest\bin;$env:JAVA_HOME\bin;$env:PATH"

Set-Location "d:\smart_expense\smart_expense"

if (Test-Path "pubspec.lock") {
    Remove-Item "pubspec.lock" -Force
}
if (Test-Path ".dart_tool") {
    Remove-Item ".dart_tool" -Recurse -Force
}

Write-Host "Running flutter pub get..."
& D:\flutter\bin\flutter.bat pub get

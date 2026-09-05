$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"
$env:ANDROID_HOME = "D:\Android\sdk"
$env:PATH = "D:\flutter\bin;D:\Android\sdk\platform-tools;D:\Android\sdk\cmdline-tools\latest\bin;$env:JAVA_HOME\bin;$env:PATH"

Write-Host "Configuring Flutter Android SDK..."
& D:\flutter\bin\flutter.bat config --android-sdk "D:\Android\sdk"
& D:\flutter\bin\flutter.bat config --jdk-dir "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"

Write-Host "Accepting Flutter Android licenses..."
$answers = ("y`n" * 30)
$answers | & D:\flutter\bin\flutter.bat doctor --android-licenses

Write-Host "Running flutter doctor..."
& D:\flutter\bin\flutter.bat doctor

Write-Host "Checking flutter devices..."
& D:\flutter\bin\flutter.bat devices

$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"
$env:ANDROID_HOME = "D:\Android\sdk"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

$sdkmanager = "D:\Android\sdk\cmdline-tools\latest\bin\sdkmanager.bat"

Write-Host "Accepting licenses..."
$answers = ("y`n" * 30)
$answers | & $sdkmanager --sdk_root="D:\Android\sdk" --licenses

Write-Host "Installing packages..."
$answers | & $sdkmanager --sdk_root="D:\Android\sdk" "platform-tools" "platforms;android-34" "build-tools;34.0.0"
Write-Host "Done installing Android packages."

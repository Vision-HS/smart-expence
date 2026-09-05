$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"
$env:ANDROID_HOME = "D:\Android\sdk"
$sdkmanager = "D:\Android\sdk\cmdline-tools\latest\bin\sdkmanager.bat"
$answers = ("y`n" * 10)
$answers | & $sdkmanager --sdk_root="D:\Android\sdk" "platforms;android-36" "build-tools;36.0.0"

[System.Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot', 'User')
[System.Environment]::SetEnvironmentVariable('ANDROID_HOME', 'D:\Android\sdk', 'User')

$userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
$toAdd = @(
    'D:\flutter\bin',
    'D:\Android\sdk\platform-tools',
    'D:\Android\sdk\cmdline-tools\latest\bin',
    'C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot\bin'
)

foreach ($p in $toAdd) {
    if ($userPath -notmatch [regex]::Escape($p)) {
        $userPath = "$p;$userPath"
    }
}
[System.Environment]::SetEnvironmentVariable('Path', $userPath, 'User')
Write-Host "User environment variables permanently configured."

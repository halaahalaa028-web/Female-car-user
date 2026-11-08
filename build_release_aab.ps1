<#
.SYNOPSIS
    Automated Release & Signed AAB Builder for Flutter Projects.
    Handles version bumping, keystore creation, Windows/Java21/AGP fixes, obfuscated build, and Play Console verification.

.EXAMPLE
    .\build_release_aab.ps1
    .\build_release_aab.ps1 -BumpType patch -Obfuscate
    .\build_release_aab.ps1 -Clean
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('build', 'patch', 'minor', 'major', 'none')]
    [string]$BumpType = 'patch',

    [Parameter(Mandatory = $false)]
    [switch]$Obfuscate = $true,

    [Parameter(Mandatory = $false)]
    [switch]$Clean = $false,

    [Parameter(Mandatory = $false)]
    [string]$ProjectPath = "."
)

$ErrorActionPreference = "Stop"

function Write-Step { param([string]$Message) Write-Host "`n====> $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Assert-FlutterProject {
    param([string]$Path)
    if (-not (Test-Path (Join-Path $Path "pubspec.yaml"))) {
        Write-Err "No pubspec.yaml found in $Path. Make sure you are in a Flutter project directory."
        exit 1
    }
}

function Bump-Version {
    param([string]$PubspecPath, [string]$Type)
    $content = Get-Content -Path $PubspecPath -Raw
    if ($content -notmatch '(?m)^version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)') {
        Write-Warn "Could not parse standard version format (x.y.z+build). Leaving version untouched."
        return $null
    }

    [int]$major = $Matches[1]; [int]$minor = $Matches[2]; [int]$patch = $Matches[3]; [int]$build = $Matches[4]
    $oldVersion = "$major.$minor.$patch+$build"

    switch ($Type) {
        'build' { $build++ }
        'patch' { $patch++; $build++ }
        'minor' { $minor++; $patch = 0; $build++ }
        'major' { $major++; $minor = 0; $patch = 0; $build++ }
        'none'  {
            # Keep unchanged
        }
    }

    $newVersion = "$major.$minor.$patch+$build"
    if ($oldVersion -ne $newVersion) {
        $content = $content -replace "(?m)^version:\s*.*$", "version: $newVersion"
        Set-Content -Path $PubspecPath -Value $content -NoNewline
        Write-Success "Version bumped: $oldVersion -> $newVersion"
    } else {
        Write-Host "Version unchanged: $oldVersion" -ForegroundColor Gray
    }
}

function Ensure-GitignoreProtection {
    param([string]$RootPath)
    $gitignore = Join-Path $RootPath ".gitignore"
    if (-not (Test-Path $gitignore)) { return }

    $entries = @("key.properties", "android/key.properties", "*.jks", "*.keystore")
    $content = Get-Content -Path $gitignore -Raw
    $toAdd = @()
    foreach ($e in $entries) {
        if ($content -notmatch [regex]::Escape($e)) { $toAdd += $e }
    }

    if ($toAdd.Count -gt 0) {
        Add-Content -Path $gitignore -Value "`n# Keystores and credentials`n$($toAdd -join "`n")"
        Write-Success "Protected keystores and credentials in .gitignore"
    }
}

function Ensure-AndroidEnvironmentFixes {
    param([string]$RootPath)
    $androidDir = Join-Path $RootPath "android"
    $gradleProps = Join-Path $androidDir "gradle.properties"
    $settingsGradle = Join-Path $androidDir "settings.gradle"
    $rootBuildGradle = Join-Path $androidDir "build.gradle"
    $wrapperProps = Join-Path $androidDir "gradle/wrapper/gradle-wrapper.properties"

    # Fix 1: Kotlin multi-drive incremental bug on Windows (C: pub cache vs D: project drive)
    if (Test-Path $gradleProps) {
        $propsContent = Get-Content -Path $gradleProps -Raw
        if ($propsContent -notmatch "kotlin\.incremental\s*=\s*false") {
            Add-Content -Path $gradleProps -Value "`nkotlin.incremental=false`norg.gradle.jvmargs=-Xmx4096m"
            Write-Success "Applied Kotlin multi-drive fix (kotlin.incremental=false) in gradle.properties"
        }
    }

    # Fix 2: AGP < 8.2.1 incompatibility with Java 21 (jlink / androidJdkImage)
    if (Test-Path $settingsGradle) {
        $settingsContent = Get-Content -Path $settingsGradle -Raw
        if ($settingsContent -match 'id\s+["'']com\.android\.application["'']\s+version\s+["'']([0-9]+\.[0-9]+\.[0-9]+)["'']') {
            if ([version]$Matches[1] -lt [version]"8.2.1") {
                $settingsContent = $settingsContent -replace 'id\s+["'']com\.android\.application["'']\s+version\s+["''][0-9]+\.[0-9]+\.[0-9]+["'']',
                    'id "com.android.application" version "8.3.2"'
                Set-Content -Path $settingsGradle -Value $settingsContent -NoNewline
                Write-Success "Upgraded AGP to 8.3.2 in settings.gradle (required for Java 21)"
            }
        }
    }

    if (Test-Path $rootBuildGradle) {
        $buildContent = Get-Content -Path $rootBuildGradle -Raw
        if ($buildContent -match 'com\.android\.tools\.build:gradle:([0-9]+\.[0-9]+\.[0-9]+)') {
            if ([version]$Matches[1] -lt [version]"8.2.1") {
                $buildContent = $buildContent -replace 'com\.android\.tools\.build:gradle:[0-9]+\.[0-9]+\.[0-9]+',
                    'com.android.tools.build:gradle:8.3.2'
                Set-Content -Path $rootBuildGradle -Value $buildContent -NoNewline
                Write-Success "Upgraded AGP classpath to 8.3.2 in root build.gradle (required for Java 21)"
            }
        }
    }

    # Ensure Gradle Wrapper >= 8.4
    if (Test-Path $wrapperProps) {
        $wrapContent = Get-Content -Path $wrapperProps -Raw
        if ($wrapContent -match 'gradle-([0-9]+\.[0-9]+(\.[0-9]+)?)-') {
            if ([version]$Matches[1] -lt [version]"8.4") {
                $wrapContent = $wrapContent -replace 'gradle-[0-9]+\.[0-9]+(\.[0-9]+)?-(bin|all)\.zip', 'gradle-8.4-all.zip'
                Set-Content -Path $wrapperProps -Value $wrapContent -NoNewline
                Write-Success "Upgraded Gradle wrapper to 8.4 in gradle-wrapper.properties"
            }
        }
    }
}

function Ensure-KeystoreAndSigning {
    param([string]$RootPath)
    $androidDir = Join-Path $RootPath "android"
    $keyProps = Join-Path $androidDir "key.properties"
    $appDir = Join-Path $androidDir "app"
    $buildGradle = Join-Path $appDir "build.gradle"

    if (-not (Test-Path $androidDir)) {
        Write-Err "Android folder not found."
        exit 1
    }

    Ensure-GitignoreProtection -RootPath $RootPath
    Ensure-AndroidEnvironmentFixes -RootPath $RootPath

    if (Test-Path $keyProps) {
        Write-Success "Found existing signing config: android/key.properties"
        return
    }

    Write-Warn "No android/key.properties found. Generating new upload keystore..."
    $alias = "upload"
    $keystoreName = "upload_keystore.jks"
    $keystorePath = Join-Path $appDir $keystoreName
    $password = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | ForEach-Object {[char]$_}) + "A1!"

    $dname = "CN=Flutter Release, OU=Mobile, O=App, L=City, ST=State, C=US"
    keytool -genkeypair -v -keystore $keystorePath -alias $alias -keyalg RSA -keysize 2048 `
        -validity 10000 -storepass $password -keypass $password -dname $dname

    $propsContent = @"
storePassword=$password
keyPassword=$password
keyAlias=$alias
storeFile=$keystoreName
"@
    Set-Content -Path $keyProps -Value $propsContent
    Write-Success "Generated keystore: android/app/$keystoreName"
    Write-Success "Created android/key.properties"

    if (Test-Path $buildGradle) {
        $gradleContent = Get-Content -Path $buildGradle -Raw
        if ($gradleContent -match "signingConfig\s+signingConfigs\.debug") {
            $gradleContent = $gradleContent -replace "signingConfig\s+signingConfigs\.debug",
                "if (keystorePropertiesFile.exists()) { signingConfig = signingConfigs.release } else { signingConfig = signingConfigs.debug }"
            Set-Content -Path $buildGradle -Value $gradleContent
            Write-Success "Configured release signing in android/app/build.gradle"
        }
    }
}

function Invoke-Build {
    param([bool]$DoClean, [bool]$DoObfuscate)

    if ($DoClean) {
        Write-Step "Cleaning project..."
        flutter clean
    }

    Write-Step "Fetching Flutter dependencies..."
    flutter pub get

    Write-Step "Building Release Android App Bundle (.aab)..."
    $buildArgs = @("build", "appbundle", "--release")
    if ($DoObfuscate) {
        $symbolsPath = "build/app/outputs/symbols"
        $buildArgs += @("--obfuscate", "--split-debug-info=$symbolsPath")
        Write-Host "Obfuscation enabled. Debug symbols output: $symbolsPath" -ForegroundColor Magenta
    }

    Write-Host "Executing: flutter $($buildArgs -join ' ')" -ForegroundColor DarkGray
    & flutter $buildArgs

    if ($LASTEXITCODE -ne 0) {
        Write-Err "Flutter build failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
}

function Show-Summary {
    param([string]$RootPath)
    $aabPath = Join-Path $RootPath "build/app/outputs/bundle/release/app-release.aab"
    if (-not (Test-Path $aabPath)) {
        Write-Err "Could not find built bundle at $aabPath"
        return
    }

    $item = Get-Item $aabPath
    $sizeMB = [math]::Round($item.Length / 1MB, 2)

    Write-Host "`n==================================================" -ForegroundColor Green
    Write-Host "       AAB BUILD COMPLETED SUCCESSFULLY!          " -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host "Location : $aabPath" -ForegroundColor White
    Write-Host "Size     : $sizeMB MB" -ForegroundColor White
    Write-Host "Built at : $($item.LastWriteTime)" -ForegroundColor White

    Write-Step "Certificate Fingerprints:"
    try {
        keytool -printcert -jarfile $aabPath | Select-String "SHA1:|SHA256:" | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Cyan
        }
    } catch {
        Write-Warn "Could not extract certificate fingerprints."
    }

    Write-Host "`nOpen containing folder? (Y/N) " -NoNewline -ForegroundColor Yellow
    $reply = Read-Host
    if ($reply -match '^[yY]') { explorer.exe /select, "$aabPath" }
}

# --- Main Flow ---
Set-Location $ProjectPath
$root = (Get-Item .).FullName
Assert-FlutterProject -Path $root

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "   Flutter Release AAB Automator Script   " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Write-Step "1/4 Checking / Bumping pubspec.yaml version..."
$null = Bump-Version -PubspecPath (Join-Path $root "pubspec.yaml") -Type $BumpType

Write-Step "2/4 Ensuring release signing, keystore & environment fixes..."
Ensure-KeystoreAndSigning -RootPath $root

Write-Step "3/4 Building Android App Bundle..."
Invoke-Build -DoClean:$Clean -DoObfuscate:$Obfuscate

Write-Step "4/4 Verification & Report..."
Show-Summary -RootPath $root

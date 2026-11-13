# FitAccess v4 - generar proyecto Android solo si falta y configurar ajustes ya probados
# Ejecutar desde PowerShell con: powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\preparar_android_windows.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root 'app_movil'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter no esta en PATH. Ejecuta flutter --version.' }
Push-Location $app
try {
    if (-not (Test-Path 'android\app\build.gradle.kts')) {
        Write-Host 'Generando plataforma Android con Flutter...' -ForegroundColor Cyan
        flutter create . --platforms=android --project-name gimnasio_facial
        if ($LASTEXITCODE -ne 0) { throw 'flutter create fallo.' }
    }
    $manifest = 'android\app\src\main\AndroidManifest.xml'
    if (-not (Test-Path $manifest)) { throw "Falta $manifest" }
    $x = Get-Content $manifest -Raw -Encoding UTF8
    if ($x -notmatch 'android.permission.INTERNET') {
        $repl = '$1' + "`r`n    <uses-permission android:name=`"android.permission.INTERNET`" />"
        $x = $x -replace '(<manifest[^>]*>)', $repl
    }
    if ($x -notmatch 'android.permission.CAMERA') {
        $repl = '$1' + "`r`n    <uses-permission android:name=`"android.permission.CAMERA`" />"
        $x = $x -replace '(<manifest[^>]*>)', $repl
    }
    if ($x -match 'android:label="[^"]*"') {
        $x = [regex]::Replace($x, 'android:label="[^"]*"', 'android:label="FitAccess"', 1)
    }
    if ($x -notmatch 'android:usesCleartextTraffic') {
        $x = $x -replace '<application', '<application android:usesCleartextTraffic="true"'
    }
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) $manifest), $x, ([System.Text.UTF8Encoding]::new($false)))

    $gradle = 'android\app\build.gradle.kts'
    $g = Get-Content $gradle -Raw -Encoding UTF8
    $g = [regex]::Replace($g, '(?m)^\s*minSdk\s*=\s*[^\r\n]+', '        minSdk = 24')
    if ($g -notmatch 'isMinifyEnabled\s*=') {
        $repl = '$1' + "`r`n            isMinifyEnabled = false`r`n            isShrinkResources = false"
        $g = $g -replace '(\brelease\s*\{)', $repl
    }
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) $gradle), $g, ([System.Text.UTF8Encoding]::new($false)))

    $props = 'android\gradle.properties'
    $gp = Get-Content $props -Raw -Encoding UTF8
    $gp = [regex]::Replace($gp, '(?m)^org\.gradle\.jvmargs=.*$', 'org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m -XX:ReservedCodeCacheSize=256m -XX:+HeapDumpOnOutOfMemoryError')
    foreach ($line in @('android.newDsl=false','android.builtInKotlin=false','kotlin.incremental=false','org.gradle.workers.max=2','org.gradle.parallel=false')) {
        if ($gp -notmatch ('(?m)^' + [regex]::Escape($line) + '$')) { $gp = $gp.TrimEnd() + "`r`n" + $line + "`r`n" }
    }
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) $props), $gp, ([System.Text.UTF8Encoding]::new($false)))

    foreach ($dpi in @('mdpi','hdpi','xhdpi','xxhdpi','xxxhdpi')) {
        $src = "android_icons\mipmap-$dpi\ic_launcher.png"
        $dst = "android\app\src\main\res\mipmap-$dpi\ic_launcher.png"
        if (Test-Path $src) { Copy-Item $src $dst -Force }
    }
    $testPlantilla = 'test\widget_test.dart'
    if (Test-Path $testPlantilla) {
        $contenidoTest = Get-Content $testPlantilla -Raw -Encoding UTF8
        if ($contenidoTest -match 'MyApp\(') {
            Remove-Item $testPlantilla -Force
            Write-Host 'Test de plantilla MyApp eliminado (no corresponde a FitAccess).'
        }
    }
    Write-Host 'Android preparado: INTERNET, CAMERA, minSdk 24, R8 desactivado, nombre e iconos FitAccess.' -ForegroundColor Green
    Write-Host 'Siguiente: flutter pub get; flutter analyze; flutter build apk --release'
} finally { Pop-Location }

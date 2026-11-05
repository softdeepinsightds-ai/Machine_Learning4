$ErrorActionPreference = "Stop"

# Define únicamente los recursos públicos que necesita la aplicación.
$routes = @{
  "/"             = @{ File = "index.html"; Type = "text/html; charset=utf-8" }
  "/index.html"    = @{ File = "index.html"; Type = "text/html; charset=utf-8" }
  "/styles.css"    = @{ File = "styles.css"; Type = "text/css; charset=utf-8" }
  "/app.js"        = @{ File = "app.js"; Type = "text/javascript; charset=utf-8" }
  "/assets/icon.svg" = @{ File = "assets\icon.svg"; Type = "image/svg+xml" }
}
$port = 8000
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)

# Busca la dirección IPv4 de la interfaz que tiene la ruta de salida predeterminada.
$defaultRoute = Get-NetRoute -DestinationPrefix "0.0.0.0/0" |
  Sort-Object RouteMetric |
  Select-Object -First 1
$localAddress = $null
if ($defaultRoute) {
  $localAddress = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $defaultRoute.InterfaceIndex |
    Where-Object { $_.IPAddress -notmatch "^(127|169\.254)\." } |
    Select-Object -First 1 -ExpandProperty IPAddress
}

# Responde solo a solicitudes GET de archivos incluidos explícitamente en la lista permitida.
function Send-StaticResponse {
  param(
    [System.Net.Sockets.TcpClient]$Client
  )

  $stream = $Client.GetStream()
  $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)
  $requestLine = $reader.ReadLine()
  while (($header = $reader.ReadLine()) -and $header.Length -gt 0) { }

  $status = "200 OK"
  $contentType = "text/plain; charset=utf-8"
  $body = [System.Text.Encoding]::UTF8.GetBytes("Not Found")

  if ($requestLine -match "^GET\s+(\S+)\s+HTTP/1\.[01]$") {
    $path = ($Matches[1] -split "\?", 2)[0]
    if ($routes.ContainsKey($path)) {
      $resource = Join-Path $PSScriptRoot $routes[$path].File
      if (Test-Path -LiteralPath $resource -PathType Leaf) {
        $status = "200 OK"
        $contentType = $routes[$path].Type
        $body = [System.IO.File]::ReadAllBytes($resource)
      } else {
        $status = "500 Internal Server Error"
        $body = [System.Text.Encoding]::UTF8.GetBytes("Application file is missing.")
      }
    } else {
      $status = "404 Not Found"
    }
  } else {
    $status = "405 Method Not Allowed"
    $body = [System.Text.Encoding]::UTF8.GetBytes("Only GET is supported.")
  }

  # Escribe la respuesta HTTP y cierra la conexión del navegador.
  $headerBytes = [System.Text.Encoding]::ASCII.GetBytes(
    "HTTP/1.1 $status`r`nContent-Type: $contentType`r`nContent-Length: $($body.Length)`r`nConnection: close`r`nX-Content-Type-Options: nosniff`r`n`r`n"
  )
  $stream.Write($headerBytes, 0, $headerBytes.Length)
  $stream.Write($body, 0, $body.Length)
  $stream.Flush()
  $reader.Dispose()
  $Client.Dispose()
}

# Inicia el servidor en la red local y atiende conexiones hasta que se pulse Ctrl+C.
try {
  $listener.Start()
  Write-Host "TipCalculator Express está disponible:"
  if ($localAddress) {
    Write-Host "  Teléfono (misma red): http://${localAddress}:$port"
  }
  Write-Host "  Esta computadora:     http://localhost:$port"
  Write-Host "Cierra con Ctrl+C. Si Windows Firewall pregunta, permite redes privadas."

  while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
      Send-StaticResponse -Client $client
    } catch {
      $client.Dispose()
      Write-Warning "No se pudo responder a una solicitud: $_"
    }
  }
} finally {
  # Libera el puerto cuando el usuario detiene el servidor.
  $listener.Stop()
}

# Prueba de interfaz en Windows de F2 (Notas y citas) y O2 (Préstamos).
# Compila Netanbook con los traits Notas y Prestamos, lo arranca y comprueba en
# el detalle de «Lazarillo de Tormes»:
#   1. Ajustes muestra los interruptores de F2 y O2 (los activa si hace falta).
#   2. F2: avisa si el texto está vacío; crea, edita y borra anotaciones.
#   3. O2: devuelve el préstamo de ejemplo (pasa al historial), avisa si falta
#      el nombre y presta el libro a otra persona con fecha de devolución.
#   4. Al reiniciar la app se conservan la nota, el préstamo y el historial.
#   5. Al eliminar el libro se borran sus notas y sus préstamos de los JSON,
#      y se conservan los de los demás libros.
# Guarda las capturas en -Carpeta (por defecto shots/notas-prestamos).
#
#   powershell -ExecutionPolicy Bypass -File scripts/probar-notas-prestamos.ps1
#
# Necesita el entorno de compilación de Swift; en Windows, el de Visual Studio
# («x64 Native Tools Command Prompt for VS 2022»). Mueve el ratón y escribe en
# la ventana de la app: no toques el ratón ni el teclado mientras se ejecuta.
# A diferencia de probar-interfaz.ps1, no pierde tus datos: aparta los
# Documentos\netanbook-*.json al empezar y los devuelve a su sitio al terminar.
# Los interruptores de Ajustes los deja como estaban, aunque la prueba falle.
# Los botones de SwiftUI se dibujan sin texto (SwiftUID2DSurface): se pulsan
# por su posición, en la fila de un texto o debajo de un campo.
param(
    [string]$Carpeta = "shots/notas-prestamos",
    [string]$ScratchPath = ""
)
$ErrorActionPreference = "Stop"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
Set-Location (Join-Path $PSScriptRoot "..")
# En la CI de GitHub, el error aparece también como anotación del workflow.
trap { Write-Host "::error title=probar-notas-prestamos.ps1::$_"; break }
. "$PSScriptRoot/ui.ps1"

$opciones = @("--traits", "Notas,Prestamos")
if ($ScratchPath) { $opciones += @("--scratch-path", $ScratchPath) }
$ErrorActionPreference = "Continue"
swift build --product Netanbook @opciones 2>&1 | ForEach-Object { "$_" } | Select-Object -Last 3
$codigo = $LASTEXITCODE
$ErrorActionPreference = "Stop"
if ($codigo -ne 0) { throw "No compila Netanbook con Notas y Prestamos" }
$bin = (swift build --product Netanbook @opciones --show-bin-path | Select-Object -Last 1).Trim()
$exe = "$bin\Netanbook.exe"

$libro = "Lazarillo de Tormes"
$idLibro = "0B1C2D3E-0003-4000-8000-000000000003"   # Book.SampleID.lazarillo
# Los textos con tildes se buscan con comodines (?), como "P?gina *" en probar-interfaz.ps1.
$ajusteNotas = "Mostrar notas y citas"
$ajustePrestamos = "Mostrar pr?stamos"

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class WinMsg {
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
}
"@

function Ir-A([string]$opcion) { if (-not (Click-Sidebar $w $opcion)) { throw "No está «$opcion» en la barra lateral" } }

# Los interruptores (Toggle) son casillas nativas de Windows: su estado se lee
# con BM_GETCHECK en vez de deducirlo de lo que muestra la app.
function Esta-Marcado([string]$patron) {
    $h = [Win]::Children($w) | Where-Object { [Win]::IsWindowVisible($_) -and [Win]::Cls($_) -eq "Button" -and [Win]::Text($_) -like $patron } | Select-Object -First 1
    if (-not $h) { throw "No hay ningún interruptor «$patron»" }
    return ([WinMsg]::SendMessage($h, 0x00F0, [IntPtr]::Zero, [IntPtr]::Zero).ToInt64() -eq 1)
}
function Poner-Interruptor([string]$patron, [bool]$valor) {
    if ((Esta-Marcado $patron) -eq $valor) { return }
    Pulsar $patron
    if ((Esta-Marcado $patron) -ne $valor) { throw "El interruptor «$patron» no cambia al pulsarlo" }
}
function Restaurar-Interruptores {
    if ($inicial.Count -eq 0) { return }
    Ir-A "Ajustes"
    foreach ($patron in $inicial.Keys) { Poner-Interruptor $patron $inicial[$patron] }
}

# Los botones de SwiftUI (Button) se dibujan como superficies SwiftUID2DSurface
# sin texto: se localizan por su posición. Primero, los de la fila de un texto.
function Botones { @(Get-Controls $w | Where-Object { $_.Class -eq "SwiftUID2DSurface" }) }
function Botones-En-Fila([string]$patron) {
    $t = Get-Controls $w | Where-Object { $_.Class -eq "Static" -and $_.Text -like $patron } | Sort-Object Y | Select-Object -First 1
    if (-not $t) { throw "No hay ningún texto «$patron»" }
    $centro = $t.Y + [int]($t.H / 2)
    return @(Botones | Where-Object { [Math]::Abs(($_.Y + [int]($_.H / 2)) - $centro) -le 15 } | Sort-Object X)
}
function Pulsar-En-Fila([string]$patron, [int]$n) {
    $fila = @(Botones-En-Fila $patron)
    if ($fila.Count -le $n) { throw "La fila «$patron» tiene $($fila.Count) botones y se buscaba el n.º $($n + 1)" }
    Click-Dentro $fila[$n]
}
# Después, los botones de la fila de un campo de texto (índice entre los
# campos, de arriba abajo; ver Escribir-En), como «Añadir» junto a la página.
function Botones-Junto-A-Campo([int]$indice) {
    $campos = @(Get-Controls $w | Where-Object { $_.Class -eq "Edit" } | Sort-Object Y, X)
    if ($campos.Count -le $indice) { throw "No hay campo de texto n.º $($indice + 1)" }
    $centro = $campos[$indice].Y + [int]($campos[$indice].H / 2)
    return @(Botones | Where-Object { [Math]::Abs(($_.Y + [int]($_.H / 2)) - $centro) -le 15 } | Sort-Object X)
}
function Pulsar-Junto-A-Campo([int]$indice, [int]$n) {
    $fila = @(Botones-Junto-A-Campo $indice)
    if ($fila.Count -le $n) { throw "Junto al campo n.º $($indice + 1) hay $($fila.Count) botones y se buscaba el n.º $($n + 1)" }
    Click-Dentro $fila[$n]
}

# Un texto del detalle se ve entero: no queda por debajo de la zona visible.
function Comprobar-Visible([string]$patron) {
    $zona = Get-Controls $w | Where-Object { $_.Class -eq "SwiftUINavContainer" } | Select-Object -First 1
    $c = Get-Controls $w | Where-Object { $_.Text -like $patron } | Select-Object -First 1
    if (-not $c) { throw "No hay ningún control «$patron»" }
    if ($zona -and ($c.Y + $c.H -gt $zona.Y + $zona.H)) { throw "«$($c.Text)» queda por debajo de la zona visible del detalle" }
}

# Menú contextual: si es un menú nativo de Windows (#32768), sus opciones no son
# ventanas y se elige la primera con el teclado; si es una ventana con textos,
# se pulsa la opción por su texto.
function Elegir-En-Menu([string]$opcion) {
    Start-Sleep -Milliseconds 800
    foreach ($top in [Win]::TopLevel([uint32]$app.Id)) {
        if ($top -eq $w -or -not [Win]::IsWindowVisible($top)) { continue }
        foreach ($c in @($top) + @([Win]::Children($top))) {
            if ([Win]::Text($c) -like $opcion) {
                $r = New-Object RECT; [Win]::GetWindowRect($c, [ref]$r) | Out-Null
                Click-At ($r.Left + [int](($r.Right - $r.Left) / 2)) ($r.Top + [int](($r.Bottom - $r.Top) / 2))
                return
            }
        }
        if ([Win]::Cls($top) -eq "#32768") { Send-Text "{DOWN}{ENTER}"; return }
    }
    throw "No aparece el menú contextual con «$opcion»"
}

# Clic solo si el centro del control está dentro de la ventana de la app y, si
# hay un detalle abierto, dentro de su zona visible: así la prueba nunca pulsa
# fuera de la app ni sobre un control recortado.
function Click-Dentro($c) {
    $x = $c.X + [int]($c.W / 2); $y = $c.Y + [int]($c.H / 2)
    $r = [Win]::Frame($w)
    if ($x -lt $r.Left -or $x -gt $r.Right -or $y -lt $r.Top -or $y -gt $r.Bottom) {
        throw "El control «$($c.Text)» ($($c.Class)) queda fuera de la ventana"
    }
    $zona = Get-Controls $w | Where-Object { $_.Class -eq "SwiftUINavContainer" } | Select-Object -First 1
    if ($zona -and ($x -lt $zona.X -or $x -gt $zona.X + $zona.W -or $y -lt $zona.Y -or $y -gt $zona.Y + $zona.H)) {
        throw "El control «$($c.Text)» ($($c.Class)) queda fuera de la zona visible del detalle ($($zona.W) x $($zona.H))"
    }
    Click-At $x $y
}

# Al volver de Ajustes a Libros, la sección ocupa todo el sitio. SwiftOpenUI la
# dejaba encogida a su tamaño mínimo; NetanbookApp lo evita (solo reconstruye la
# sección elegida) y esta comprobación vigila que no vuelva a pasar.
function Comprobar-Ocupa-Todo([string]$momento) {
    $zona = Get-Controls $w | Where-Object { $_.Class -eq "SwiftUINavContainer" } | Select-Object -First 1
    if (-not $zona) { throw "No hay contenedor de navegación ($momento)" }
    $r = [Win]::Frame($w)
    if ($zona.W -lt ($r.Right - $r.Left) * 0.6 -or $zona.H -lt ($r.Bottom - $r.Top) * 0.8) {
        throw "La sección Libros está encogida ($momento): $($zona.W) x $($zona.H)"
    }
}

# Ningún control visible del detalle se superpone a otro. SwiftOpenUI no
# recoloca las secciones de abajo cuando una crece por un estado local; esta
# comprobación lo detecta en vez de dejar que un clic caiga en otro control.
function Comprobar-Sin-Solapes([string]$momento) {
    $zona = Get-Controls $w | Where-Object { $_.Class -eq "SwiftUINavContainer" } | Select-Object -First 1
    if (-not $zona) { return }
    $hojas = @(Get-Controls $w | Where-Object {
        $_.Class -in @("Static", "Edit", "Button", "SwiftUID2DSurface", "SwiftUIDropdownTrigger") -and
        $_.W -gt 0 -and $_.H -gt 0 -and $_.X -ge $zona.X -and $_.Y -ge $zona.Y -and
        $_.X + $_.W -le $zona.X + $zona.W + 1 -and $_.Y + $_.H -le $zona.Y + $zona.H + 1 })
    for ($i = 0; $i -lt $hojas.Count; $i++) {
        for ($j = $i + 1; $j -lt $hojas.Count; $j++) {
            $a = $hojas[$i]; $b = $hojas[$j]
            $ancho = [Math]::Min($a.X + $a.W, $b.X + $b.W) - [Math]::Max($a.X, $b.X)
            $alto = [Math]::Min($a.Y + $a.H, $b.Y + $b.H) - [Math]::Max($a.Y, $b.Y)
            if ($ancho -gt 2 -and $alto -gt 2) {
                throw "Controles superpuestos ($momento): «$($a.Text)» ($($a.Class) en $($a.X),$($a.Y)) y «$($b.Text)» ($($b.Class) en $($b.X),$($b.Y))"
            }
        }
    }
}

# Pulsa el control más alto de la ventana cuyo texto cumple el patrón.
function Pulsar([string]$patron) {
    $c = Get-Controls $w | Where-Object { $_.Text -like $patron } | Sort-Object Y, X | Select-Object -First 1
    if (-not $c) { throw "No hay ningún control «$patron»" }
    Click-Dentro $c
}

# Campos de texto del detalle, de arriba abajo: 0 título, 1 texto de la nota,
# 2 página, 3 persona y 4 días de préstamo (las secciones tienen siempre las
# mismas filas, así que siempre hay 5).
function Escribir-En([int]$indice, [string]$texto, [int]$esperados) {
    $campos = @(Get-Controls $w | Where-Object { $_.Class -eq "Edit" } | Sort-Object Y, X)
    if ($campos.Count -ne $esperados) {
        $lista = ($campos | ForEach-Object { "[$($_.Y)] '$($_.Text)'" }) -join ", "
        throw "Se esperaban $esperados campos de texto y hay $($campos.Count): $lista"
    }
    Click-Dentro $campos[$indice]
    Send-Text $texto
}

function Abrir-Libro { if (-not (Click-Text $w $libro)) { throw "No está la fila de $libro" } }
# Las secciones se reconocen por su cabecera, que sí es un texto de Windows.
function Ver-Notas { (Count-Text $w "Notas y citas") -gt 0 }
function Ver-Prestamos { (Count-Like $w "Pr?stamo") -gt 0 }
function Comprobar([bool]$condicion, [string]$mensaje) { if (-not $condicion) { throw $mensaje } }

function Leer-Json([string]$nombre) {
    $ruta = Join-Path $documentos $nombre
    if (-not (Test-Path $ruta)) { return }
    # En Windows PowerShell, ConvertFrom-Json devuelve la lista entera como un
    # solo objeto: ForEach-Object la separa en elementos.
    Get-Content $ruta -Raw -Encoding UTF8 | ConvertFrom-Json | ForEach-Object { $_ }
}

# Apartar los datos guardados (se devuelven al terminar) para empezar con los de ejemplo.
$documentos = [Environment]::GetFolderPath("MyDocuments")
$apartados = Join-Path ([IO.Path]::GetTempPath()) ("netanbook-apartados-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Force -Path $apartados | Out-Null
Get-ChildItem $documentos -Filter "netanbook-*.json" -ErrorAction SilentlyContinue | Move-Item -Destination $apartados
$app = $null
$inicial = @{}
try {
    # 1. Ajustes: están los interruptores de F2 y O2; se activan para la prueba
    #    y al terminar se dejan como estaban.
    $app = Start-App $exe "np-1"
    $w = Get-AppWindow $app.Id
    Write-Host "Ventana: $([Win]::Text($w))"
    Ir-A "Ajustes"
    Snap $w $Carpeta "np-1-ajustes"
    $inicial[$ajusteNotas] = Esta-Marcado $ajusteNotas
    $inicial[$ajustePrestamos] = Esta-Marcado $ajustePrestamos
    Write-Host "Ajustes al empezar: notas=$($inicial[$ajusteNotas]) prestamos=$($inicial[$ajustePrestamos])"
    Poner-Interruptor $ajusteNotas $true
    Poner-Interruptor $ajustePrestamos $true

    Ir-A "Libros"
    Comprobar-Ocupa-Todo "listado tras volver de Ajustes"
    Abrir-Libro
    Comprobar-Ocupa-Todo "detalle tras volver de Ajustes"
    Snap $w $Carpeta "np-2-detalle-inicial"
    Comprobar-Sin-Solapes "np-2-detalle-inicial"
    Comprobar (Ver-Notas) "Con el ajuste activado no se ve la sección de notas"
    Comprobar (Ver-Prestamos) "Con el ajuste activado no se ve la sección de préstamo"
    Comprobar ((Count-Like $w "Este libro no tiene notas*") -eq 1) "El libro debería empezar sin notas"
    Comprobar ((Count-Like $w "Prestado a Ana el *") -eq 1) "No se ve el préstamo de ejemplo (Ana)"

    # 2. F2: el texto vacío no se guarda y avisa; después, crear, editar y borrar.
    Pulsar-Junto-A-Campo 2 0                                   # «Añadir» sin texto
    Comprobar ((Count-Like $w "Escribe el texto de la nota*") -eq 1) "No avisa de que falta el texto de la nota"
    Comprobar-Sin-Solapes "aviso de nota vacía"
    Escribir-En 1 "Prueba de nota" 5
    Escribir-En 2 "12" 5
    Pulsar-Junto-A-Campo 2 0                                   # «Añadir»
    Snap $w $Carpeta "np-3-nota-anadida"
    Comprobar-Sin-Solapes "np-3-nota-anadida"
    Comprobar ((Count-Like $w "Nota: Prueba de nota (p. 12)") -eq 1) "No aparece la nota añadida"
    Comprobar ((Count-Like $w "Este libro no tiene notas*") -eq 0) "Sigue el aviso de libro sin notas"
    Comprobar ((Count-Like $w "Escribe el texto de la nota*") -eq 0) "Sigue el aviso de texto vacío"

    Pulsar-En-Fila "Nota: Prueba de nota (p. 12)" 0          # «Editar»
    Comprobar (@(Botones-Junto-A-Campo 2).Count -eq 2) "Al editar deberían aparecer «Guardar cambios» y «Cancelar»"
    Escribir-En 1 "{END} editada" 5
    Pulsar-Junto-A-Campo 2 0                                   # «Guardar cambios»
    Snap $w $Carpeta "np-4-nota-editada"
    Comprobar-Sin-Solapes "np-4-nota-editada"
    Comprobar ((Count-Like $w "Nota: Prueba de nota editada (p. 12)") -eq 1) "No se ve la nota editada"
    Comprobar (@(Botones-Junto-A-Campo 2).Count -eq 1) "Tras guardar, el formulario debería volver a «Añadir»"

    Escribir-En 1 "Para borrar" 5
    Pulsar-Junto-A-Campo 2 0                                   # «Añadir»
    Comprobar ((Count-Like $w "Nota: Para borrar") -eq 1) "No aparece la segunda nota"
    Pulsar-En-Fila "Nota: Para borrar" 1                    # «Borrar»
    Snap $w $Carpeta "np-5-nota-borrada"
    Comprobar-Sin-Solapes "np-5-nota-borrada"
    Comprobar ((Count-Like $w "Nota: Para borrar") -eq 0) "No se ha borrado la nota"
    Comprobar ((Count-Like $w "Nota: Prueba de nota editada (p. 12)") -eq 1) "Se ha borrado la nota equivocada"

    # 3. O2: devolver el préstamo de ejemplo y prestar el libro a otra persona.
    Pulsar-En-Fila "Prestado a Ana el *" 0                  # «Marcar como devuelto»
    Snap $w $Carpeta "np-6-prestamo-devuelto"
    Comprobar-Sin-Solapes "np-6-prestamo-devuelto"
    Comprobar ((Count-Like $w "Este libro est? en casa") -eq 1) "Tras devolverlo, el libro debería estar en casa"
    Comprobar ((Count-Like $w "Devuelto ? Ana: *") -eq 1) "El préstamo devuelto no pasa al historial"
    Comprobar-Visible "Devuelto ? Ana: *"
    Pulsar-Junto-A-Campo 4 0                                   # «Prestar» sin nombre
    Comprobar ((Count-Like $w "Escribe a qui?n se lo prestas") -eq 1) "No avisa de que falta el nombre"
    Comprobar-Sin-Solapes "aviso de préstamo sin nombre"
    Escribir-En 3 "Marta" 5
    Escribir-En 4 "7" 5
    Pulsar-Junto-A-Campo 4 0                                   # «Prestar»
    Snap $w $Carpeta "np-7-prestado-a-marta"
    Comprobar-Sin-Solapes "np-7-prestado-a-marta"
    Comprobar ((Count-Like $w "Prestado a Marta el * devolver el *") -eq 1) "No aparece el nuevo préstamo con su fecha de devolución"

    # 4. Al reiniciar se conservan la nota, el préstamo y el historial.
    Stop-Process -Id $app.Id -Force; Start-Sleep -Seconds 2
    $app = Start-App $exe "np-2"
    $w = Get-AppWindow $app.Id
    Abrir-Libro
    Snap $w $Carpeta "np-8-tras-reiniciar"
    Comprobar-Sin-Solapes "np-8-tras-reiniciar"
    Comprobar ((Count-Like $w "Nota: Prueba de nota editada (p. 12)") -eq 1) "No se ha conservado la nota"
    Comprobar ((Count-Like $w "Prestado a Marta el *") -eq 1) "No se ha conservado el préstamo"
    Comprobar ((Count-Like $w "Devuelto ? Ana: *") -eq 1) "No se ha conservado el historial de préstamos"

    # 5. Al eliminar el libro se borran sus notas y sus préstamos, y no los de otros libros.
    Comprobar (Click-Back $w) "No hay botón para volver al listado"
    Comprobar (Click-Text $w $libro -Right) "No está la fila de $libro"
    Elegir-En-Menu "Eliminar libro"
    Start-Sleep -Seconds 1
    Snap $w $Carpeta "np-9-libro-eliminado"
    Comprobar ((Count-Text $w $libro) -eq 0) "El libro sigue en el listado"
    $notas = @(Leer-Json "netanbook-notas.json")
    $prestamos = @(Leer-Json "netanbook-prestamos.json")
    Comprobar (@($notas | Where-Object { $_.bookID -eq $idLibro }).Count -eq 0) "Quedan notas del libro borrado"
    Comprobar (@($prestamos | Where-Object { $_.bookID -eq $idLibro }).Count -eq 0) "Quedan préstamos del libro borrado"
    Comprobar ($notas.Count -eq 2) "Deberían quedar las 2 notas de ejemplo de otros libros y hay $($notas.Count)"
    Comprobar ($prestamos.Count -eq 1) "Debería quedar 1 préstamo de ejemplo de otro libro y hay $($prestamos.Count)"

    # Dejar los ajustes como estaban.
    Restaurar-Interruptores
    $inicial = @{}
    Write-Host "::notice title=Interfaz (Notas y Préstamos)::Notas y préstamos se crean, editan, borran, se conservan al reiniciar y se borran con su libro"
    Write-Host "Prueba de interfaz de F2 y O2 superada"
}
finally {
    if ($app -and -not $app.HasExited) {
        try { Restaurar-Interruptores } catch { Write-Host "No se han podido dejar los ajustes como estaban: $_" }
        Stop-Process -Id $app.Id -Force; Start-Sleep -Seconds 2
    }
    Get-ChildItem $documentos -Filter "netanbook-*.json" -ErrorAction SilentlyContinue | Remove-Item
    Get-ChildItem $apartados -Filter "netanbook-*.json" -ErrorAction SilentlyContinue | Move-Item -Destination $documentos
    Remove-Item $apartados -ErrorAction SilentlyContinue
}

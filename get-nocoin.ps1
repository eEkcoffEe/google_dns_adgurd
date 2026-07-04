# ============================================
# Скрипт для скачивания и очистки adblock-nocoin-list
# Формат: hosts.txt (0.0.0.0 domain.com)
# Результат: nocoin_clean.txt
# ============================================

$url = "https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/hosts.txt"
$outputFile = "nocoin_clean.txt"

Write-Host "Скачивание списка с $url ..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 60
    $lines = $response.Content -split "`n"
    Write-Host "Скачано $($lines.Count) строк." -ForegroundColor Green
}
catch {
    Write-Host "Ошибка при скачивании: $_" -ForegroundColor Red
    exit 1
}

$domains = [System.Collections.Generic.HashSet[string]]::new()
$comments = [System.Collections.Generic.List[string]]::new()
$emptyLinesCount = 0
$ipLinesCount = 0
$invalidLinesCount = 0

$ipv4Pattern = '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'
$domainPattern = '^([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'

foreach ($rawLine in $lines) {
    $line = $rawLine.Trim()
    
    # Пустые строки
    if ([string]::IsNullOrWhiteSpace($line)) {
        $emptyLinesCount++
        continue
    }
    
    # Комментарии сохраняем
    if ($line.StartsWith('#')) {
        [void]$comments.Add($line)
        continue
    }
    
    $domain = $null
    
    # Формат hosts: 0.0.0.0 domain.com
    if ($line.StartsWith('0.0.0.0 ') -or $line.StartsWith('127.0.0.1 ')) {
        $parts = $line -split '\s+'
        if ($parts.Count -ge 2) {
            $domain = $parts[1]
            $ipLinesCount++
        }
        else {
            $invalidLinesCount++
            continue
        }
    }
    # Чистый домен
    elseif ($line -match $domainPattern) {
        $domain = $line
    }
    else {
        $invalidLinesCount++
        continue
    }
    
    # Убираем завершающую точку
    $domain = $domain.TrimEnd('.')
    
    # Пропускаем IP-адреса
    if ($domain -match $ipv4Pattern) {
        $invalidLinesCount++
        continue
    }
    
    # Проверяем валидность домена
    if (-not ($domain.Contains('.') -and $domain -match '[a-zA-Z]$')) {
        $invalidLinesCount++
        continue
    }
    
    $domain = $domain.ToLower()
    
    # Добавляем в HashSet (автоматически убирает дубликаты)
    [void]$domains.Add($domain)
}

# Сортируем домены
$sortedDomains = $domains | Sort-Object

# Сохраняем в файл (UTF-8 без BOM)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$outputLines = [System.Collections.Generic.List[string]]::new()

# Сначала комментарии
foreach ($comment in $comments) {
    [void]$outputLines.Add($comment)
}

# Пустая строка между комментариями и доменами
[void]$outputLines.Add("")

# Затем отсортированные домены
foreach ($domain in $sortedDomains) {
    [void]$outputLines.Add($domain)
}

[System.IO.File]::WriteAllLines((Join-Path $PWD $outputFile), $outputLines, $utf8NoBom)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "СТАТИСТИКА" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Всего строк в оригинале : $($lines.Count)" -ForegroundColor Gray
Write-Host "Пустых строк удалено    : $emptyLinesCount" -ForegroundColor Gray
Write-Host "Комментариев сохранено  : $($comments.Count)" -ForegroundColor Green
Write-Host "Строк hosts обработано  : $ipLinesCount" -ForegroundColor Gray
Write-Host "Невалидных строк        : $invalidLinesCount" -ForegroundColor Gray
Write-Host "Уникальных доменов      : $($sortedDomains.Count)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Файл сохранён: $(Join-Path $PWD $outputFile)" -ForegroundColor Yellow

# ============================================
# Скрипт для удаления дубликатов из Edit_Blocklist.txt
# Результат: Edit_Blocklist_clean.txt
# ============================================

$url = "https://raw.githubusercontent.com/eEkcoffEe/google_dns_adgurd/refs/heads/main/Edit_Blocklist.txt"
$outputFile = "Edit_Blocklist_clean.txt"

Write-Host "Скачивание файла с $url ..." -ForegroundColor Cyan

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
$duplicatesCount = 0

foreach ($rawLine in $lines) {
    $line = $rawLine.Trim()
    
    # Пустые строки
    if ([string]::IsNullOrWhiteSpace($line)) {
        $emptyLinesCount++
        continue
    }
    
    # Комментарии сохраняем отдельно
    if ($line.StartsWith('#')) {
        [void]$comments.Add($line)
        continue
    }
    
    # Приводим к нижнему регистру для корректного сравнения
    $domain = $line.ToLower()
    
    # Проверяем, есть ли уже такой домен
    if (-not $domains.Contains($domain)) {
        [void]$domains.Add($domain)
    }
    else {
        $duplicatesCount++
    }
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
Write-Host "Уникальных доменов      : $($sortedDomains.Count)" -ForegroundColor Green
Write-Host "Дубликатов удалено      : $duplicatesCount" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Файл сохранён: $(Join-Path $PWD $outputFile)" -ForegroundColor Yellow

# ============================================
# Скрипт для скачивания нескольких списков AdGuard
# и фильтрации доменов по ключевому слову
# Результат: filtered_domains.txt
# ============================================

# === НАСТРОЙКИ ===
$urls = @(
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt",
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_62.txt",
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt",
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_8.txt",
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_12.txt",
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt",
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt",
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_31.txt",
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_6.txt",
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_63.txt",
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_71.txt",
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_56.txt",
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt",
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_49.txt",
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt"
)
$outputFile = "filtered_domains.txt"
$keyword = "google"   # <-- Измените на любое другое слово при необходимости
# ================

# Общий HashSet для всех доменов (автоматически убирает дубликаты между списками)
$domains = [System.Collections.Generic.HashSet[string]]::new()
$ipv4Pattern = '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'
$domainPattern = '^([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'

$totalLines = 0
$totalSkippedByKeyword = 0
$successCount = 0
$failCount = 0

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Обработка $($urls.Count) списков AdGuard" -ForegroundColor Cyan
Write-Host "Ключевое слово: '$keyword'" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$counter = 0
foreach ($url in $urls) {
    $counter++
    $listName = [System.IO.Path]::GetFileName($url)
    Write-Host "[$counter/$($urls.Count)] $listName ... " -NoNewline -ForegroundColor Yellow

    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 60
        $lines = $response.Content -split "`n"
        $totalLines += $lines.Count
        Write-Host "OK ($($lines.Count) строк)" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "ОШИБКА: $_" -ForegroundColor Red
        $failCount++
        continue
    }

    $listSkipped = 0

    foreach ($rawLine in $lines) {
        $line = $rawLine.Trim()

        # Пропускаем пустые строки и комментарии
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.StartsWith('!') -or $line.StartsWith('#') -or $line.StartsWith('[') -or $line.StartsWith('/')) { continue }

        $domain = $null

        # Синтаксис Adblock: ||domain.com^
        if ($line.StartsWith('||')) {
            $domain = $line.Substring(2)

            if ($domain.Contains('$')) {
                $domain = $domain.Split('$')[0]
            }
            if ($domain.EndsWith('^')) {
                $domain = $domain.Substring(0, $domain.Length - 1)
            }
            if ($domain -match '[\*/\?]') { continue }
        }
        # Синтаксис hosts: 0.0.0.0 domain.com
        elseif ($line.StartsWith('0.0.0.0 ') -or $line.StartsWith('127.0.0.1 ')) {
            $parts = $line -split '\s+'
            if ($parts.Count -ge 2) {
                $domain = $parts[1]
                if ($domain -match '[\*/\?]') { continue }
            }
            else { continue }
        }
        # Чистые домены
        elseif ($line -match $domainPattern) {
            $domain = $line
        }
        else {
            continue
        }

        $domain = $domain.TrimEnd('.')

        if ($domain -match $ipv4Pattern) { continue }
        if (-not ($domain.Contains('.') -and $domain -match '[a-zA-Z]$')) { continue }

        $domain = $domain.ToLower()

        # === ФИЛЬТР ПО КЛЮЧЕВОМУ СЛОВУ ===
        if ($domain -notlike "*$keyword*") {
            $listSkipped++
            continue
        }

        [void]$domains.Add($domain)
    }

    $totalSkippedByKeyword += $listSkipped
}

# Сортируем и сохраняем
$sorted = $domains | Sort-Object
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines((Join-Path $PWD $outputFile), $sorted, $utf8NoBom)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ИТОГ" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Обработано списков : $successCount из $($urls.Count)" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "Ошибок загрузки    : $failCount" -ForegroundColor Red
}
Write-Host "Всего строк        : $totalLines" -ForegroundColor Gray
Write-Host "Пропущено по фильтру: $totalSkippedByKeyword (не содержат '$keyword')" -ForegroundColor Gray
Write-Host "Найдено уникальных : $($sorted.Count) доменов" -ForegroundColor Cyan
Write-Host "Файл сохранён      : $(Join-Path $PWD $outputFile)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

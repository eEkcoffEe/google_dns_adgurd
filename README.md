Вот готовый README.md для вашего репозитория:

```markdown
# PowerShell скрипты для обработки DNS-блок-листов Adblock

Набор PowerShell-скриптов для скачивания, очистки и фильтрации DNS-блок-листов из различных источников (AdGuard, GitHub) для использования в **Adblock на OpenWrt роутере**.

## 📋 Описание

Скрипты автоматизируют процесс подготовки доменных списков для локального блок-листа Adblock на OpenWrt. Они:

- ✅ Скачивают списки из интернета
- ✅ Очищают от синтаксиса Adblock (`||`, `^`), hosts-формата (`0.0.0.0`), модификаторов (`$important`)
- ✅ Отфильтровывают wildcards (`*`), regex, пути и IP-адреса
- ✅ Удаляют дубликаты
- ✅ Сохраняют только чистые домены (по одному на строку)
- ✅ Поддерживают фильтрацию по ключевому слову

## 🎯 Назначение

Все скрипты созданы для подготовки списков в формате, совместимом с **Edit Blocklist** в Adblock на OpenWrt:

```
# Один домен на строку
# Комментарии начинаются с #
# Без IP-адресов, wildcards и regex
domain.com
subdomain.domain.com
```

## 📁 Скрипты

### 1. `get-multi-domains.ps1`

Скачивает **15 списков AdGuard DNS filter** одновременно, объединяет их и фильтрует только домены, содержащие определённое ключевое слово (по умолчанию — `google`).

**Источники:**
- filter_1.txt (AdGuard DNS filter)
- filter_6.txt, filter_8.txt, filter_9.txt
- filter_12.txt, filter_18.txt, filter_30.txt
- filter_31.txt, filter_49.txt, filter_50.txt
- filter_56.txt, filter_59.txt, filter_62.txt
- filter_63.txt, filter_71.txt

**Настройки:**
```powershell
$keyword = "google"  # Измените на любое другое слово
```

**Результат:** `filtered_domains.txt` — все уникальные домены со словом "google" из всех 15 списков.

**Пример использования:**
```powershell
# Фильтр по "google" (по умолчанию)
.\get-multi-domains.ps1

# Измените $keyword в начале скрипта на "youtube", "facebook", "ads" и т.д.
```

---

### 2. `remove-duplicates.ps1`

Скачивает файл `Edit_Blocklist.txt` из репозитория, удаляет все дубликаты и сохраняет чистую версию.

**Источник:**
```
https://raw.githubusercontent.com/eEkcoffEe/google_dns_adgurd/refs/heads/main/Edit_Blocklist.txt
```

**Результат:** `Edit_Blocklist_clean.txt` — отсортированный список без дубликатов.

**Пример использования:**
```powershell
.\remove-duplicates.ps1
```

---

### 3. `get-nocoin.ps1`

Скачивает список **adblock-nocoin-list** (блок-лист крипто-майнеров) и очищает его от hosts-синтаксиса.

**Источник:**
```
https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/hosts.txt
```

**Результат:** `nocoin_clean.txt` — список доменов крипто-майнеров.

**Пример использования:**
```powershell
.\get-nocoin.ps1
```

## 🚀 Как запустить

### Требования
- Windows 10/11 или PowerShell 5.1+
- Доступ в интернет

### Запуск

1. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/ваш-username/ваш-репозиторий.git
   cd ваш-репозиторий
   ```

2. Запустите нужный скрипт:
   ```powershell
   # Если политика выполнения блокирует скрипты:
   powershell -ExecutionPolicy Bypass -File .\get-multi-domains.ps1
   powershell -ExecutionPolicy Bypass -File .\remove-duplicates.ps1
   powershell -ExecutionPolicy Bypass -File .\get-nocoin.ps1
   ```

3. После выполнения в папке появятся готовые файлы:
   - `filtered_domains.txt`
   - `Edit_Blocklist_clean.txt`
   - `nocoin_clean.txt`

## 🔧 Использование на OpenWrt

### Шаг 1: Подготовка списка

Запустите нужный скрипт на Windows-компьютере. Получите файл `.txt` с доменами.

### Шаг 2: Загрузка в Adblock

1. Откройте веб-интерфейс OpenWrt (LuCI)
2. Перейдите в **Services → Adblock**
3. В разделе **Edit Blocklist** вставьте содержимое файла
4. Сохраните и примените

### Шаг 3: Альтернативный способ (через SSH)

```bash
# Скопируйте файл на роутер
scp filtered_domains.txt root@192.168.1.1:/tmp/

# Подключитесь к роутеру
ssh root@192.168.1.1

# Добавьте домены в блок-лист Adblock
cat /tmp/filtered_domains.txt >> /etc/adblock/adblock.blacklist

# Перезапустите Adblock
/etc/init.d/adblock restart
```

## 📊 Статистика

Все скрипты выводят подробную статистику после выполнения:

```
========================================
СТАТИСТИКА
========================================
Всего строк в оригинале : 65432
Пустых строк удалено    : 1234
Комментариев сохранено  : 15
Уникальных доменов      : 5555
Дубликатов удалено      : 69
========================================
```

## ⚙️ Настройка

### Изменение ключевого слова

В скрипте `get-multi-domains.ps1` измените переменную `$keyword` в начале файла:

```powershell
$keyword = "youtube"     # Все домены YouTube
$keyword = "facebook"    # Все домены Facebook
$keyword = "doubleclick" # Только DoubleClick
$keyword = "ads"         # Все домены со словом "ads"
$keyword = "tracker"     # Все трекеры
```

### Добавление новых источников

В скрипте `get-multi-domains.ps1` добавьте URL в массив `$urls`:

```powershell
$urls = @(
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt",
    # Добавьте свой URL здесь:
    "https://example.com/your-list.txt"
)
```

## 📝 Примечания

- Все скрипты сохраняют файлы в **UTF-8 без BOM** для корректной работы Adblock
- Домены автоматически приводятся к **нижнему регистру**
- Дубликаты удаляются автоматически через `HashSet`
- Комментарии (`#`) из оригинальных файлов сохраняются в начале результирующего файла
- Wildcards (`*`), regex (`/.../`) и IP-адреса отфильтровываются

## 🔗 Источники списков

- [AdGuard DNS Filter](https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt)
- [AdGuard DNS Filter (все списки)](https://adguardteam.github.io/HostlistsRegistry/)
- [adblock-nocoin-list](https://github.com/hoshsadiq/adblock-nocoin-list)
- [Edit_Blocklist.txt](https://github.com/eEkcoffEe/google_dns_adgurd)

## 📄 Лицензия

Скрипты созданы для личного использования. Используйте на свой страх и риск.

## 🤝 Вклад

Если у вас есть предложения по улучшению скриптов или хотите добавить новые источники — создайте Issue или Pull Request.

---

**Автор:** [eEkcoffEe]  
**Дата создания:** Июль 2026  
**Версия:** 1.0
```

Этот README.md полностью описывает ваш репозиторий, объясняет назначение каждого скрипта, показывает как их запускать и использовать на OpenWrt роутере. Вы можете скопировать его и сохранить как `README.md` в корне вашего репозитория.

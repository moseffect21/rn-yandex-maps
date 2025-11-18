@echo off
setlocal enabledelayedexpansion

REM Скрипт для публикации @moseffect21/rn-yandex-maps в npm (Windows)
REM Использование: scripts\publish.bat [patch|minor|major]

set VERSION_TYPE=%1
if "%VERSION_TYPE%"=="" set VERSION_TYPE=patch

echo [INFO] 🚀 Начинаем публикацию @moseffect21/rn-yandex-maps
echo [INFO] Тип обновления версии: %VERSION_TYPE%

REM Проверка, что мы в правильной директории
if not exist "package.json" (
    echo [ERROR] package.json не найден. Запустите скрипт из корневой директории проекта.
    exit /b 1
)

REM Проверка авторизации в npm
echo [INFO] 🔐 Проверка авторизации в npm...
npm whoami >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Вы не авторизованы в npm. Выполните: npm login
    exit /b 1
)

for /f %%i in ('npm whoami') do set NPM_USER=%%i
echo [SUCCESS] Авторизован как: %NPM_USER%

REM Установка зависимостей
echo [INFO] 📦 Установка зависимостей...
yarn install
if errorlevel 1 (
    echo [ERROR] Ошибка при установке зависимостей
    exit /b 1
)

REM Компиляция TypeScript
echo [INFO] 🔨 Компиляция TypeScript...
npm run prepublishOnly
if errorlevel 1 (
    echo [ERROR] Ошибка компиляции TypeScript
    exit /b 1
)
echo [SUCCESS] TypeScript скомпилирован успешно

REM Проверка содержимого пакета
echo [INFO] 📋 Проверка содержимого пакета...
npm pack --dry-run

REM Обновление версии
echo [INFO] 📈 Обновление версии (%VERSION_TYPE%)...
for /f %%i in ('node -p "require('./package.json').version"') do set OLD_VERSION=%%i
npm version %VERSION_TYPE% --no-git-tag-version
for /f %%i in ('node -p "require('./package.json').version"') do set NEW_VERSION=%%i
echo [SUCCESS] Версия обновлена: %OLD_VERSION% → %NEW_VERSION%

REM Создание архива для финальной проверки
echo [INFO] 📦 Создание архива пакета...
for /f %%i in ('npm pack') do set PACKAGE_FILE=%%i
echo [SUCCESS] Архив создан: %PACKAGE_FILE%

REM Подтверждение публикации
echo.
echo [WARNING] Готов к публикации:
echo   Пакет: @moseffect21/rn-yandex-maps
echo   Версия: %NEW_VERSION%
echo   Пользователь: %NPM_USER%
echo.
set /p CONFIRM="Опубликовать пакет? (y/N): "

if /i not "%CONFIRM%"=="y" (
    echo [INFO] Публикация отменена.
    npm version %OLD_VERSION% --no-git-tag-version
    del "%PACKAGE_FILE%" 2>nul
    exit /b 0
)

REM Публикация
echo [INFO] 🚀 Публикация пакета в npm...
npm publish --access public
if errorlevel 1 (
    echo [ERROR] ❌ Ошибка при публикации пакета
    npm version %OLD_VERSION% --no-git-tag-version
    del "%PACKAGE_FILE%" 2>nul
    exit /b 1
)

echo [SUCCESS] ✅ Пакет успешно опубликован!
echo [SUCCESS] 📦 @moseffect21/rn-yandex-maps@%NEW_VERSION%

REM Очистка временного файла
del "%PACKAGE_FILE%" 2>nul

REM Создание git тега и коммита
echo [INFO] 🏷️  Создание git тега...
git add package.json
git commit -m "chore: bump version to %NEW_VERSION%"
git tag "v%NEW_VERSION%"
echo [SUCCESS] Git тег v%NEW_VERSION% создан

REM Отправка в GitHub
echo [INFO] 📤 Отправка изменений в GitHub...
git push origin master
git push origin "v%NEW_VERSION%"
echo [SUCCESS] Изменения отправлены в GitHub

REM Информация для пользователей
echo.
echo [SUCCESS] 🎉 Публикация завершена!
echo.
echo [INFO] Пользователи могут установить пакет:
echo   npm install @moseffect21/rn-yandex-maps@%NEW_VERSION%
echo   yarn add @moseffect21/rn-yandex-maps@%NEW_VERSION%
echo.
echo [INFO] Проверить пакет:
echo   npm view @moseffect21/rn-yandex-maps
echo.
echo [INFO] GitHub Release:
echo   https://github.com/moseffect21/rn-yandex-maps/releases/tag/v%NEW_VERSION%


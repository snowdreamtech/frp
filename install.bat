@echo off
:: install.bat — UniRTM installer for Windows (CMD wrapper)
:: Delegates all logic to install.ps1 via PowerShell.
:: Usage: install.bat [--version v0.7.0]
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*

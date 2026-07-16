:: This script generates sleep study report

@echo off
set XmlFilePath=%1
set HtlmFilePath=%2
powercfg.exe /sleepstudy /duration 5 /output %XmlFilePath% /xml >nul
POWERCFG /SLEEPSTUDY /TRANSFORMXML %XmlFilePath% /OUTPUT %HtlmFilePath% >nul
EXIT /B %ERRORLEVEL%


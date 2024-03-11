@echo off

set ideargs=

:next
if not "%~1"=="" (
  (set "ideargs=%ideargs%%1 ")
  shift
  goto next
)

start devenv.exe %ideargs%
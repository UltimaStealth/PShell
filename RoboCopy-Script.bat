@echo off

SET SORC="\\SERVERNAME\d$"
SET DEST="D:\d$"
SET LOG="C:\PATH TO LOG.log"

ROBOCOPY %SORC% %DEST% /DCOPY:T /COPYALL /MIR /MT:16 /MON:1 /SEC /R:1 /W:1 /ETA /LOG:%LOG%
@if errorlevel 16 echo ***ERROR *** & goto END
@if errorlevel 8  echo **FAILED COPY ** & goto END
@if errorlevel 4  echo *MISMATCHES *      & goto END
@if errorlevel 2  echo EXTRA FILES       & goto END
@if errorlevel 1  echo --Copy Successful--  & goto END
@if errorlevel 0  echo --Copy Successful--  & goto END
goto END

:END

pause

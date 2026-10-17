@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

echo ╭──────────────────────────────────────────╮
echo │   📥 Bulk /(YouTube^|Video)/ Downloader   │
echo │            by EDM115 (Modified)          │
echo ╰──────────────────────────────────────────╯
echo.

echo 🔍 Checking requirements...
call :require_cmd yt-dlp || goto :fatal
call :require_cmd ffmpeg || goto :fatal
call :require_cmd ffprobe || goto :fatal

if not exist "links.txt" (
  echo ❌ links.txt not found in "%CD%"
  goto :fatal
)

if not exist "downloads\" (
  mkdir "downloads" >nul 2>&1
)

echo ✅ All good !
echo.

echo 🎛️ Choose download format:
echo   [1] Video ^(Best quality + Subtitles^)
echo   [2] MP3 ^(Audio only^)
set "dl_choice="
set /p "dl_choice=👉 Enter your choice [1/2] (Default is 1): "

if "%dl_choice%"=="2" goto :mode_audio
goto :mode_video

:mode_audio
echo 🎵 Audio Mode Selected ^(MP3^)
set DEFAULT_ARGS=-x --audio-format mp3 --audio-quality 0 --embed-thumbnail --embed-metadata --embed-chapters --yes-playlist --windows-filenames --progress --console-title --concurrent-fragments 4 --ignore-errors -P "downloads" -o "%%(playlist_title|.)s/%%(playlist_index&{} - |)s%%(title)s [%%(id)s].%%(ext)s"
goto :mode_done

:mode_video
echo 🎬 Video Mode Selected
set DEFAULT_ARGS=-f "bestvideo+bestaudio/best" --embed-subs --embed-thumbnail --embed-metadata --embed-chapters --yes-playlist --windows-filenames --progress --console-title --concurrent-fragments 4 --ignore-errors -P "downloads" -o "%%(playlist_title|.)s/%%(playlist_index&{} - |)s%%(title)s [%%(id)s].%%(ext)s"

:mode_done
echo.

if not "%~1"=="" (
  echo 🧩 Extra yt-dlp args detected ^(they override defaults if duplicated^) :
  echo    %*
  echo.
)

echo 📜 Parsing links.txt...
set count=0

for /f "usebackq delims=" %%A in ("links.txt") do (
  set "line=%%A"

  REM Remove indentation/whitespace, quotes, and trailing commas
  set "line=!line: =!"
  set "line=!line:"=!"
  set "line=!line:,=!"

  REM Skip empty/brackets
  if not "!line!"=="" if /i not "!line!"=="[" if /i not "!line!"=="]" (
    set /a count+=1
    set "url[!count!]=!line!"
  )
)

if !count! EQU 0 (
  echo ❌ No URLs found in links.txt !
  goto :fatal
)

echo 🎯 !count! links found !
echo.

for /l %%i in (1,1,!count!) do (
  echo 🔗 Processing link %%i/!count!
  set "current_url=!url[%%i]!"
  set "current_url=!current_url:"=!"
  set "current_url=!current_url:,=!"

  echo 🔍 Checking link type...
  set "pl_title="
  set "pl_count="

  for /f "usebackq delims=" %%B in (`yt-dlp --flat-playlist --playlist-end 1 --print "%%(playlist_title)s" "!current_url!" 2^>nul`) do set "pl_title=%%B"
  for /f "usebackq delims=" %%B in (`yt-dlp --flat-playlist --playlist-end 1 --print "%%(playlist_count)s" "!current_url!" 2^>nul`) do set "pl_count=%%B"

  if defined pl_count if not "!pl_count!"=="" (
    echo.
    echo 📋 Playlist Detected!
    if defined pl_title echo    Title : !pl_title!
    echo    Total : !pl_count! items found.
    echo.
    set /p "start_vid=👉 Enter start number (Press Enter for 1): "
    if "!start_vid!"=="" set "start_vid=1"

    set /p "end_vid=👉 Enter end number (Press Enter for !pl_count!): "
    if "!end_vid!"=="" set "end_vid=!pl_count!"

    set "range_arg=--playlist-items !start_vid!-!end_vid!"
    echo 🎯 Will download items from !start_vid! to !end_vid!.
  ) else (
    set "range_arg="
    echo 🎬 Single link detected.
  )

  echo.
  echo ⏬ Downloading !current_url! ...
  echo.

  REM Put range_arg first so it takes precedence over playlist defaults
  yt-dlp !range_arg! %DEFAULT_ARGS% %* "!current_url!"
  echo.
)

echo 🎉 Download done !
echo 🗃️ Your files are in the "downloads" folder
echo.
echo 🫂 Follow me on GitHub :
echo    https://github.com/EDM115
echo.
pause
endlocal
exit /b 0

:require_cmd
where /q %~1 >nul 2>&1
if errorlevel 1 (
  echo ❌ "%~1" not found in PATH
  echo    💡 Tip : add the folder containing %~1.exe to your PATH
  exit /b 1
)
echo 🔰 Found %~1
exit /b 0

:fatal
echo.
echo ❗ Exiting...
pause
endlocal
exit /b 1
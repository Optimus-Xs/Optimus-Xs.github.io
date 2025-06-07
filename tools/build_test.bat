@echo off
SETLOCAL

SET SERVICE_NAME=jekyll
SET JEKYLL_DEST_DIR=_site


echo Starting Jekyll build and HTML Proofer checks within the Docker container...

docker compose exec -it %SERVICE_NAME% bash -c "JEKYLL_ENV=\"production\" bundle exec jekyll build -d \"%JEKYLL_DEST_DIR%\" && bundle exec htmlproofer %JEKYLL_DEST_DIR% --disable-external --no-enforce-https --allow_missing_href --ignore-urls \"/^http://127.0.0.1/,/^http://0.0.0.0/,/^http://localhost/\""

IF %ERRORLEVEL% NEQ 0 (
    echo Error: Command failed.
    EXIT /B %ERRORLEVEL%
)

echo Site build and test process finished successfully.
ENDLOCAL
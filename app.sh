#!/bin/bash
# 1. - 
# export $(cat .env | xargs) && cabal run

# 2. -
# DB_HOST=db.prod DB_PORT=5432 DB_USER=app DB_PASS=secret DB_NAME=myapp ./main
# .env
#   DB_HOST=localhost
#   DB_NAME=postgres
#   DB_USER=postgres
#   DB_PASS=xophjeju

# 3. -
#set -a          # все новые переменные автоматически экспортируются
#source .env     # или: . ./.env
#set +a          # вернуть обычное поведение

cabal run

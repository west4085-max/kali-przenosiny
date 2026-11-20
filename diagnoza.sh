#!/usr/bin/env bash
echo "HOME=$HOME  user=$(whoami)"
echo "== opencode =="
command -v opencode || echo BRAK_W_PATH
opencode --version 2>&1 | head -2
npm ls -g --depth=0 opencode-ai 2>&1 | tail -2
echo "== klucz =="
K="$HOME/.config/venice/api_key"
ls -l "$K" 2>&1
echo -n "bajty: "; wc -c < "$K" 2>&1
echo -n "po usunieciu spacji: "; tr -d '[:space:]' < "$K" 2>/dev/null | wc -c
echo "== config =="
C="$HOME/.config/opencode/opencode.jsonc"
ls -l "$C" 2>&1
sed -n '1,14p' "$C" 2>&1
echo "== pakiety providera =="
ls "$HOME/.config/opencode/node_modules/@ai-sdk" 2>&1
echo "== modele venice =="
timeout 60 opencode models 2>&1 | grep 'deepseek-v4-1' || echo "BRAK NASZEGO MODELU"
echo "== proba rozmowy =="
cd "$HOME" && timeout 90 opencode run --model venice/deepseek-v4-1-flash-1017-uncensored "Odpowiedz jednym słowem: dziala" 2>&1 | tail -15

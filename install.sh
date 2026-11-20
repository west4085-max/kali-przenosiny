#!/usr/bin/env bash
set -u
echo "== OpenCode: instalacja z archiwum na telefonie =="

if [ "$(id -u)" -eq 0 ]; then echo "Uruchom jako zwykły użytkownik, nie root."; exit 1; fi
command -v apt >/dev/null || { echo "To nie wygląda na Kali/Debian."; exit 1; }

sudo -v || { echo "Potrzebne jest sudo."; exit 1; }
sudo apt update -qq
sudo apt install -y nodejs npm tmux rsync simple-mtpfs >/dev/null 2>&1 || sudo apt install -y nodejs npm tmux rsync

WERSJA=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)
if [ "$WERSJA" -lt 22 ]; then
  echo "Aktualizuję Node.js do 22..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - >/dev/null
  sudo apt install -y nodejs >/dev/null
fi
command -v opencode >/dev/null || sudo npm install -g opencode-ai

echo "Szukam archiwum kali-przenosiny.tar.gz..."
PLIK=""
for d in "$HOME" "$HOME/Download" "$HOME/Pobrane" "$HOME/Desktop" "$HOME/Pulpit" "/media/$USER" /mnt; do
  [ -d "$d" ] || continue
  p=$(find "$d" -maxdepth 3 -name 'kali-przenosiny.tar.gz' 2>/dev/null | head -1)
  if [ -n "$p" ]; then PLIK="$p"; break; fi
done
if [ -z "$PLIK" ]; then
  p=$(find "/run/user/$(id -u)/gvfs" -maxdepth 5 -name 'kali-przenosiny.tar.gz' 2>/dev/null | head -1)
  [ -n "$p" ] && PLIK="$p"
fi
MTP=0
if [ -z "$PLIK" ] && command -v simple-mtpfs >/dev/null; then
  mkdir -p /tmp/mtp
  for nr in $(simple-mtpfs -l 2>/dev/null | cut -d: -f1); do
    if simple-mtpfs --device "$nr" /tmp/mtp 2>/dev/null; then
      MTP=1
      p=$(find /tmp/mtp -maxdepth 5 -name 'kali-przenosiny.tar.gz' 2>/dev/null | head -1)
      [ -n "$p" ] && PLIK="$p" && break
      fusermount -u /tmp/mtp 2>/dev/null
    fi
  done
fi
if [ -z "$PLIK" ]; then
  echo "Nie znalazłem archiwum automatycznie."
  echo "Podaj pełną ścieżkę do kali-przenosiny.tar.gz:"
  read -r PLIK
fi
[ -f "$PLIK" ] || { echo "Nie ma pliku: $PLIK"; exit 1; }
echo "Archiwum: $PLIK"

T=$(mktemp -d)
tar -xzf "$PLIK" -C "$T" || { echo "Rozpakowanie nie udało się."; exit 1; }
bash "$T/install.sh"
rm -rf "$T"
[ "$MTP" = 1 ] && fusermount -u /tmp/mtp 2>/dev/null

if opencode models 2>/dev/null | grep -q 'deepseek-v4-1-flash-1017-uncensored'; then
  echo "MODEL WIDOCZNY — konfiguracja działa."
else
  echo "UWAGA: modelu nie widać, sprawdź ~/.config/venice/api_key"
fi
echo "KONIEC. Uruchom: opencode"

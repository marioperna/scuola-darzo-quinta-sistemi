#!/bin/bash
# =====================================================================
#  init.sh - Prepara l'ambiente per la prova formativa "Linux da terminale"
#  Uso (da utente normale, SENZA sudo):   bash init.sh
#
#  Crea la cartella ~/materiale con:
#    .impostazioni_lab                  file nascosto          (consegna A2)
#    log/server.log                     log di 300 righe       (C2-C5)
#    progetti/.../segreto.txt           file da cercare        (D2)
#    video/lezione01.mp4                file da 5 MB           (D3, G2)
#    riservato/voti.txt                 permessi rw-rw-rw-     (E4)
#    script/calcolo.py                  processo "calcolo_lab" (G3, G4)
#  Si puo' rilanciare: ricrea tutto da capo.
# =====================================================================

# 1. Controllo: non va eseguito come root, altrimenti i file finiscono in /root
if [ "$(id -u)" -eq 0 ]; then
    echo "ERRORE: non usare sudo. Lancia lo script cosi': bash init.sh"
    exit 1
fi

BASE="$HOME/materiale"
echo "Preparo l'ambiente in $BASE ..."

# 2. Se lo script era gia' stato lanciato: fermo il vecchio processo e ricreo la cartella
pkill -f "materiale/script/calcolo.py" 2>/dev/null
rm -rf "$BASE"

# 3. Struttura delle cartelle
mkdir -p "$BASE/log" "$BASE/riservato" "$BASE/video" "$BASE/script"
mkdir -p "$BASE/progetti/rete/switch" "$BASE/progetti/rete/cablaggio"
mkdir -p "$BASE/progetti/web/sito/css" "$BASE/progetti/web/sito/img"
mkdir -p "$BASE/progetti/archivio/2023" "$BASE/progetti/archivio/2024/backup"

# 4. File nascosto (A2)
echo "lab=informatica" > "$BASE/.impostazioni_lab"
echo "postazioni=28"  >> "$BASE/.impostazioni_lab"

# 5. Log del server: 300 righe, esattamente 6 righe ERROR (C2-C5)
LOG="$BASE/log/server.log"
: > "$LOG"
MSG_INFO=("Richiesta GET /index.html" "Richiesta GET /css/stile.css" "Utente collegato: studente"
          "Richiesta GET /img/logo.png" "Utente scollegato: studente" "Backup automatico completato")
for i in $(seq 0 299); do
    s=$((8 * 3600 + i * 37))                                   # dalle 08:00:00, una riga ogni 37 secondi
    ora=$(printf "%02d:%02d:%02d" $((s / 3600)) $((s % 3600 / 60)) $((s % 60)))
    if [ $i -eq 0 ]; then
        riga="INFO    Avvio del server web"
    elif [ $i -eq 299 ]; then
        riga="INFO    Arresto del server completato"
    else
        case $i in
            37)  riga="ERROR   Disco quasi pieno sulla partizione /var" ;;
            82)  riga="ERROR   Connessione al database rifiutata" ;;
            120) riga="ERROR   File /var/www/contatti.html non trovato" ;;
            171) riga="ERROR   Timeout della richiesta da 192.168.1.47" ;;
            205) riga="ERROR   Permesso negato su /etc/nginx/nginx.conf" ;;
            266) riga="ERROR   Memoria esaurita nel processo php-fpm" ;;
            *)
                if [ $((i % 23)) -eq 0 ]; then
                    riga="WARNING Tempo di risposta elevato: $((900 + i)) ms"
                else
                    riga="INFO    ${MSG_INFO[$((i % 6))]}"
                fi ;;
        esac
    fi
    echo "2026-11-04 $ora $riga" >> "$LOG"
done

# 6. File da cercare con find (D1-D2): alcuni file "esca" e il file segreto
echo "porta=8080"        > "$BASE/progetti/web/config.txt"
echo "vlan=10"           > "$BASE/progetti/rete/config.txt"
echo "switch=24 porte"   > "$BASE/progetti/rete/switch/note.txt"
echo "cavo=cat6"         > "$BASE/progetti/rete/cablaggio/note.txt"
echo "<h1>Benvenuti</h1>" > "$BASE/progetti/web/sito/index.html"
echo "body { color: navy; }" > "$BASE/progetti/web/sito/css/stile.css"
echo "Progetto chiuso"   > "$BASE/progetti/archivio/2023/relazione.txt"
echo "Parola chiave: PINGUINO-1991" > "$BASE/progetti/archivio/2024/backup/segreto.txt"

# 7. File grande da 5 MB (D3 e G2)
dd if=/dev/zero of="$BASE/video/lezione01.mp4" bs=1048576 count=5 2>/dev/null

# 8. File con permessi troppo aperti (E4)
printf "Rossi 7\nBianchi 8\nVerdi 6\n" > "$BASE/riservato/voti.txt"
chmod 666 "$BASE/riservato/voti.txt"

# 9. Processo di prova (G3-G4): usa circa meta' di un core e si ferma da solo dopo 2 ore
cat > "$BASE/script/calcolo.py" << 'FINE'
import ctypes, time
try:
    ctypes.CDLL(None).prctl(15, b"calcolo_lab", 0, 0, 0)   # nome visibile in top
except Exception:
    pass
fine = time.time() + 7200
while time.time() < fine:
    t = time.time() + 0.05
    while time.time() < t:
        pass                # lavora 50 ms...
    time.sleep(0.05)        # ...e riposa 50 ms
FINE
if command -v python3 > /dev/null; then
    nohup python3 "$BASE/script/calcolo.py" > /dev/null 2>&1 &
else
    echo "ATTENZIONE: python3 non trovato, processo di prova non avviato (G3-G4)."
fi

echo ""
echo "Ambiente pronto. Puoi iniziare la prova."

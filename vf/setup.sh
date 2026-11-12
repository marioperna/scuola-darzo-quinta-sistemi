#!/bin/bash
# ------------------------------------------------------------
# setup.sh - Prepara l'ambiente della verifica "Comandi Linux"
# Tema: server dell'azienda NovaTech S.r.l.
# Uso:  bash setup.sh      (NON usare sudo, NON modificare)
# Se viene rilanciato, ricrea tutto da capo.
# Durante la prova la connessione a Internet viene bloccata e ogni
# tentativo di uscire in rete viene registrato. consegna.sh la ripristina.
# ------------------------------------------------------------

BASE="$HOME/novatech"

echo "Preparazione dell'ambiente NovaTech in corso..."

# --- 0. Rete e strumenti (la rete serve ora, il blocco arriva alla fine) ---
# Se c'e' un blocco precedente (script rilanciato) lo toglie, cosi' la rete funziona.
for cmd in iptables ip6tables; do
    sudo $cmd -D OUTPUT -j NOVATECH_BLOCK 2>/dev/null
    sudo $cmd -F NOVATECH_BLOCK 2>/dev/null
    sudo $cmd -X NOVATECH_BLOCK 2>/dev/null
done

# Installa subito gli strumenti che servono durante la prova, perche'
# dopo il blocco non sara' piu' possibile scaricare nulla.
echo "Installazione degli strumenti (serve qualche minuto)..."
sudo apt-get update -qq > /dev/null 2>&1
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq build-essential zip iptables > /dev/null 2>&1
if ! command -v g++ > /dev/null || ! command -v zip > /dev/null || ! command -v iptables > /dev/null; then
    echo "ATTENZIONE: installazione incompleta (g++, zip o iptables mancanti). Avvisa il docente."
fi

# --- 1. Pulizia di un eventuale ambiente precedente ----------
pkill -f fantasma.sh 2>/dev/null
rm -rf "$BASE"
for utente in gverdi mrossi lbianchi; do
    sudo deluser --remove-home "$utente" >/dev/null 2>&1
done
for gruppo in stagisti tirocinanti contabili gverdi mrossi lbianchi; do
    sudo groupdel "$gruppo" >/dev/null 2>&1
done

# --- 2. Struttura delle cartelle ------------------------------
mkdir -p "$BASE/da_sistemare/temp"
mkdir -p "$BASE/log"
mkdir -p "$BASE/riservato"
mkdir -p "$BASE/strumenti"
mkdir -p "$BASE/condivisa/marketing/2024/vecchi"
mkdir -p "$BASE/condivisa/video"
mkdir -p "$BASE/condivisa/manuali"

# --- 3. File da riordinare ------------------------------------
echo "Fattura n. 101 - gennaio - cliente Alfa S.p.A. - 1200 euro"  > "$BASE/da_sistemare/fattura_gennaio.txt"
echo "Fattura n. 102 - febbraio - cliente Beta S.r.l. - 850 euro"  > "$BASE/da_sistemare/fattura_febbraio.txt"
echo "Fattura n. 103 - marzo - cliente Gamma S.n.c. - 430 euro"    > "$BASE/da_sistemare/fattura_marzo.txt"
echo "Contratto di assistenza - cliente Alfa S.p.A."               > "$BASE/da_sistemare/contratto_alfa.txt"
echo "Contratto di fornitura - cliente Beta S.r.l."                > "$BASE/da_sistemare/contratto_beta.txt"
echo "Ricordarsi di cambiare la password del Wi-Fi ogni 3 mesi."   > "$BASE/da_sistemare/bozza.txt"
echo "file temporaneo" > "$BASE/da_sistemare/temp/cache1.tmp"
echo "file temporaneo" > "$BASE/da_sistemare/temp/cache2.tmp"
echo "file temporaneo" > "$BASE/da_sistemare/temp/vecchio_download.tmp"

# --- 4. File nascosto -----------------------------------------
echo "File lasciato dal vecchio sistemista" > "$BASE/.vecchio_sistemista"

# --- 5. Log degli accessi (48 righe, 7 accessi falliti) -------
LOG="$BASE/log/accessi.log"
: > "$LOG"
utenti=(amministrazione magazzino direzione vendite)
ip=(192.168.10.21 192.168.10.34 192.168.10.47 192.168.10.52)
for i in $(seq 1 48); do
    ora=$(printf "%02d:%02d:%02d" $((8 + i / 6)) $(((i * 7) % 60)) $(((i * 13) % 60)))
    n=$((i % 4))
    case $i in
        1)  echo "2026-11-09 07:58:03 INFO Avvio del servizio di accesso" >> "$LOG" ;;
        9|15|16|17|28|29|40)
            echo "2026-11-09 $ora ERRORE Accesso FALLITO utente=root ip=203.0.113.45" >> "$LOG" ;;
        22|35)
            echo "2026-11-09 $ora AVVISO Spazio su disco in esaurimento" >> "$LOG" ;;
        48) echo "2026-11-09 16:05:40 INFO Accesso riuscito utente=gverdi ip=192.168.10.99" >> "$LOG" ;;
        *)  echo "2026-11-09 $ora INFO Accesso riuscito utente=${utenti[$n]} ip=${ip[$n]}" >> "$LOG" ;;
    esac
done

# --- 6. File riservato e strumenti ----------------------------
echo "Stipendi NovaTech - documento riservato alla direzione" > "$BASE/riservato/stipendi.txt"
chmod 644 "$BASE/riservato/stipendi.txt"

cat > "$BASE/strumenti/backup.sh" << 'EOF'
#!/bin/bash
echo "Backup NovaTech: controllo completato, nessun errore."
EOF
chmod 644 "$BASE/strumenti/backup.sh"

cat > "$BASE/strumenti/inventario.cpp" << 'EOF'
#include <iostream>
using namespace std;

int main() {
    cout << "Inventario NovaTech" << endl;
    cout << "PC in ufficio: 24" << endl;
    cout << "Stampanti: 3" << endl;
    return 0;
}
EOF

# --- 7. Cartella condivisa ------------------------------------
echo "Rete: NovaTech-Uffici  -  Password: Girasole#2026" > "$BASE/condivisa/marketing/2024/vecchi/password_wifi.txt"
echo "Volantino fiera 2024" > "$BASE/condivisa/marketing/2024/volantino.txt"
echo "Manuale della stampante" > "$BASE/condivisa/manuali/stampante.txt"
echo "Manuale del centralino" > "$BASE/condivisa/manuali/centralino.txt"
head -c 3M /dev/urandom > "$BASE/condivisa/video/presentazione.mp4"

# --- 8. Rapporto da compilare ---------------------------------
RAPPORTO="$BASE/rapporto.txt"
echo "RAPPORTO DEL SISTEMISTA - NovaTech S.r.l." > "$RAPPORTO"
echo "Cognome e nome: " >> "$RAPPORTO"
echo "Classe: " >> "$RAPPORTO"
echo "" >> "$RAPPORTO"
for i in $(seq 1 16); do
    echo "R$i: " >> "$RAPPORTO"
done

# --- 9. Utente e gruppo gia' presenti sul server --------------
sudo useradd -m -s /bin/bash -c "Giorgio Verdi" gverdi
echo "gverdi:Novatech2025" | sudo chpasswd
sudo groupadd stagisti
sudo usermod -aG stagisti gverdi

# --- 10. Processo anomalo -------------------------------------
cat > /tmp/fantasma.sh << 'EOF'
#!/bin/bash
while true; do
    :
done
EOF
chmod +x /tmp/fantasma.sh
setsid nohup /tmp/fantasma.sh > /dev/null 2>&1 &

# --- 11. Registrazione dei comandi digitati -------------------
# Ogni comando viene salvato subito in ~/.bash_history, con data e ora.
# Se esiste un blocco di una versione precedente lo toglie (e' sempre in fondo al file).
if grep -q "VERIFICA-NOVATECH" "$HOME/.bashrc" 2>/dev/null; then
    sed -i '/VERIFICA-NOVATECH/,$d' "$HOME/.bashrc"
fi
echo '# VERIFICA-NOVATECH: salvataggio immediato dei comandi' >> "$HOME/.bashrc"
echo 'export HISTFILE="$HOME/.bash_history"' >> "$HOME/.bashrc"
echo 'shopt -s histappend' >> "$HOME/.bashrc"
echo 'HISTSIZE=5000' >> "$HOME/.bashrc"
echo 'HISTFILESIZE=5000' >> "$HOME/.bashrc"
echo 'HISTCONTROL=' >> "$HOME/.bashrc"
echo 'HISTTIMEFORMAT="%H:%M:%S  "' >> "$HOME/.bashrc"
echo 'PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"' >> "$HOME/.bashrc"
: > "$HOME/.bash_history"
date "+%Y-%m-%d %H:%M:%S" > "$BASE/.inizio_prova"

# --- 12. Blocco della rete ----------------------------------------
# Tutto il traffico in uscita viene respinto, tranne quello locale (lo).
# L'interfaccia resta configurata, quindi "ip addr" mostra ancora l'indirizzo.
# Prima di respingere, ogni pacchetto viene scritto nel log del kernel
# (prefisso NOVATECH-BLOCCO), con un massimo di 20 righe al minuto.
for cmd in iptables ip6tables; do
    command -v $cmd > /dev/null || continue
    sudo $cmd -N NOVATECH_BLOCK
    sudo $cmd -A NOVATECH_BLOCK -o lo -j RETURN
    sudo $cmd -A NOVATECH_BLOCK -m limit --limit 20/min --limit-burst 20 -j LOG --log-prefix "NOVATECH-BLOCCO " 2>/dev/null
    sudo $cmd -A NOVATECH_BLOCK -j REJECT
    sudo $cmd -I OUTPUT 1 -j NOVATECH_BLOCK
done
if sudo iptables -C OUTPUT -j NOVATECH_BLOCK 2>/dev/null; then
    BLOCCO="Internet BLOCCATO"
else
    BLOCCO="ATTENZIONE: blocco di rete NON attivo, avvisa il docente"
fi

# --- 13. Apertura automatica del nuovo terminale -------------------
# Il nuovo terminale legge il .bashrc appena modificato, quindi registra i comandi.
# Parte staccato da questo script: resta aperto anche se si chiude il vecchio.
AVVIO='clear; echo "============================================================"; echo " Terminale della verifica pronto."; echo " Da qui in poi i comandi vengono registrati."; echo " Puoi chiudere il terminale precedente."; echo "============================================================"; echo; cd ~; exec bash -i'
APERTO=0
if [ -n "$DISPLAY$WAYLAND_DISPLAY" ]; then
    for t in gnome-terminal ptyxis xterm x-terminal-emulator; do
        command -v $t > /dev/null || continue
        case $t in
            gnome-terminal|ptyxis) setsid nohup $t -- bash -c "$AVVIO" > /dev/null 2>&1 & ;;
            *)                     setsid nohup $t -e bash -c "$AVVIO" > /dev/null 2>&1 & ;;
        esac
        APERTO=1
        break
    done
fi

echo ""
echo "============================================================"
echo " Ambiente pronto.  ($BLOCCO)"
if [ $APERTO -eq 1 ]; then
    echo " Si sta aprendo un NUOVO TERMINALE: usa quello per la prova."
    echo " Puoi chiudere questo."
else
    echo " ORA CHIUDI QUESTO TERMINALE E APRINE UNO NUOVO (Ctrl+Alt+T)."
fi
echo " I comandi digitati in QUESTO terminale non vengono registrati."
echo "============================================================"

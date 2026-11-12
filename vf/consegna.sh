#!/bin/bash
# ------------------------------------------------------------
# consegna.sh - Salva il lavoro svolto nella verifica "Comandi Linux"
# Uso:  history -a ; bash consegna.sh      (NON usare sudo)
# Crea nella home il file consegna_COGNOME_NOME.tar.gz che contiene:
#   - comandi.txt   tutti i comandi digitati al terminale, con l'ora
#   - rapporto.txt  le risposte scritte dallo studente
#   - stato.txt     la situazione finale di file, utenti, gruppi e processi
#   - internet.txt  il controllo sui tentativi di collegarsi a Internet
# Alla fine ripristina la connessione a Internet bloccata da setup.sh.
# ------------------------------------------------------------

BASE="$HOME/novatech"

# Controllo preliminare: ci sono comandi registrati?
NCOMANDI=$(grep -vc '^#' "$HOME/.bash_history" 2>/dev/null)
if [ "${NCOMANDI:-0}" -lt 3 ]; then
    echo "ATTENZIONE: nella cronologia ci sono solo ${NCOMANDI:-0} comandi."
    echo "Forse stai usando il terminale in cui hai lanciato setup.sh, oppure i"
    echo "comandi non sono ancora stati salvati. Digita:   history -a"
    echo "poi rilancia:   bash consegna.sh"
    read -p "Vuoi continuare comunque? (s/N) " risp
    [ "$risp" = "s" ] || exit 1
fi

read -p "Cognome: " cognome
read -p "Nome: " nome
read -p "Classe: " classe

# Nome della cartella di consegna, senza spazi
nomefile="consegna_${cognome// /}_${nome// /}"
DEST="$HOME/$nomefile"
rm -rf "$DEST"
mkdir -p "$DEST"

# --- 1. Comandi digitati ---------------------------------------
# Nel file della cronologia ogni comando e' preceduto da una riga
# "#numero" che indica l'istante in cui e' stato eseguito.
echo "Studente: $cognome $nome - Classe: $classe" > "$DEST/comandi.txt"
echo "Inizio prova: $(cat "$BASE/.inizio_prova" 2>/dev/null)" >> "$DEST/comandi.txt"
echo "Consegna:     $(date "+%Y-%m-%d %H:%M:%S")" >> "$DEST/comandi.txt"
echo "------------------------------------------------------------" >> "$DEST/comandi.txt"
ora=""
while IFS= read -r riga; do
    if [[ "$riga" =~ ^#[0-9]+$ ]]; then
        ora=$(date -d "@${riga:1}" "+%H:%M:%S")
    else
        echo "$ora  $riga" >> "$DEST/comandi.txt"
    fi
done < "$HOME/.bash_history"

# --- 2. Rapporto con le risposte --------------------------------
cp "$BASE/rapporto.txt" "$DEST/rapporto.txt" 2>/dev/null

# --- 3. Stato finale del sistema --------------------------------
STATO="$DEST/stato.txt"
echo "===== FILE E CARTELLE IN ~/novatech =====" > "$STATO"
ls -laR "$BASE" >> "$STATO" 2>&1
echo "" >> "$STATO"
echo "===== UTENTI (righe di /etc/passwd) =====" >> "$STATO"
grep -E "^(mrossi|lbianchi|gverdi):" /etc/passwd >> "$STATO"
echo "" >> "$STATO"
echo "===== ACCOUNT BLOCCATI (L = bloccato) =====" >> "$STATO"
for utente in mrossi lbianchi gverdi; do
    sudo passwd -S "$utente" >> "$STATO" 2>&1
done
echo "" >> "$STATO"
echo "===== GRUPPI (righe di /etc/group) =====" >> "$STATO"
grep -E "^(contabili|stagisti|tirocinanti):" /etc/group >> "$STATO"
echo "" >> "$STATO"
echo "===== ID DEGLI UTENTI =====" >> "$STATO"
id mrossi >> "$STATO" 2>&1
id lbianchi >> "$STATO" 2>&1
echo "" >> "$STATO"
echo "===== PROCESSO fantasma.sh (vuoto = terminato) =====" >> "$STATO"
ps aux | grep "fantasma.sh" | grep -v grep >> "$STATO"
echo "" >> "$STATO"
echo "===== CONTENUTO DEGLI ARCHIVI =====" >> "$STATO"
tar tzf "$BASE/archivio/backup/fatture.tar.gz" >> "$STATO" 2>&1
unzip -l "$BASE/archivio/backup/contratti.zip" >> "$STATO" 2>&1

# --- 4. Controllo di Internet -----------------------------------
NET="$DEST/internet.txt"
echo "Studente: $cognome $nome - Classe: $classe" > "$NET"
echo "" >> "$NET"
echo "===== BLOCCO DELLA RETE =====" >> "$NET"
if sudo iptables -C OUTPUT -j NOVATECH_BLOCK 2>/dev/null; then
    echo "Blocco ancora attivo fino alla consegna: regolare." >> "$NET"
else
    echo "ATTENZIONE: il blocco e' stato rimosso o modificato durante la prova." >> "$NET"
fi
echo "" >> "$NET"
echo "===== TENTATIVI DI USCIRE IN RETE =====" >> "$NET"
echo "Pacchetti respinti (il sistema ne genera alcuni da solo, per aggiornamenti e orologio):" >> "$NET"
sudo iptables -L NOVATECH_BLOCK -v -n -x 2>/dev/null | awk '/REJECT/ {print "  " $1 " pacchetti"}' >> "$NET"
echo "Destinazioni piu' frequenti (indirizzo:porta; 443 e 80 = siti web, 53 = ricerca di nomi):" >> "$NET"
sudo dmesg 2>/dev/null | grep NOVATECH-BLOCCO | awk '{d="";p="-"; for(i=1;i<=NF;i++){ if($i ~ /^DST=/) d=substr($i,5); if($i ~ /^DPT=/) p=substr($i,5)} print d":"p}' | sort | uniq -c | sort -rn | head -20 >> "$NET"
echo "" >> "$NET"
echo "===== COMANDI SOSPETTI NELLA CRONOLOGIA =====" >> "$NET"
echo "(rete, firewall, browser, download, installazioni; esclusi i comandi di setup e consegna)" >> "$NET"
grep -E "iptables|ip6tables|nft|nmcli|ip link|ifconfig|rfkill|curl|wget|ping|firefox|chrom|ssh|apt|snap|pip|git " "$DEST/comandi.txt" | grep -vE "setup.sh|consegna.sh" >> "$NET"

# --- 5. Pacchetto finale ----------------------------------------
cd "$HOME"
tar czf "$nomefile.tar.gz" "$nomefile"

# --- 6. Ripristino della rete ------------------------------------
for cmd in iptables ip6tables; do
    sudo $cmd -D OUTPUT -j NOVATECH_BLOCK 2>/dev/null
    sudo $cmd -F NOVATECH_BLOCK 2>/dev/null
    sudo $cmd -X NOVATECH_BLOCK 2>/dev/null
done

echo ""
echo "============================================================"
echo " Lavoro salvato nel file: $HOME/$nomefile.tar.gz"
echo " Comandi registrati: $(grep -vc '^#' "$HOME/.bash_history")"
echo " Connessione a Internet ripristinata."
echo " NON spegnere il PC: chiama il docente per la consegna."
echo "============================================================"

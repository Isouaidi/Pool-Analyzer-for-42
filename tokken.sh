#!/bin/bash

while true; do
    read -p "Entrez votre client_id (UID) : " CLIENT_ID
    read -p "Entrez votre client_secret : " CLIENT_SECRET
    echo

    RESPONSE=$(curl -s -X POST "https://api.intra.42.fr/oauth/token" \
        -d "grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}")

    # Extraction de "error" (si présent)
    ERROR=$(echo "$RESPONSE" | grep -o '"error":"[^"]*"' | sed 's/"error":"\(.*\)"/\1/')

    if [ -n "$ERROR" ]; then
        echo "Erreur d'authentification : $ERROR"
        echo "Merci de vérifier vos identifiants."
        echo
    else
        ACCESS_TOKEN=$(echo "$RESPONSE" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"\(.*\)"/\1/')
        break
    fi
done

while true; do
    echo "Lancement du script..."
    python3 api.py "$ACCESS_TOKEN"

    echo
    read -p "Souhaitez-vous relancer le script ? (o/n) : " RESTART
    if [[ "$RESTART" =~ ^[Nn]$ ]]; then
        echo "Fin du script."
        break
    fi
done

exit 0

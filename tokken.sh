#!/bin/bash

TOKEN_FILE="token.txt"
VALIDATION_URL="https://api.intra.42.fr/v2/me"

function get_new_token() {
    while true; do
        read -p "Entrez votre client_id (UID) : " CLIENT_ID
        read -p "Entrez votre client_secret : " CLIENT_SECRET
        echo

        RESPONSE=$(curl -s -X POST "https://api.intra.42.fr/oauth/token" \
            -d "grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}")

        ERROR=$(echo "$RESPONSE" | grep -o '"error":"[^"]*"' | sed 's/"error":"\(.*\)"/\1/')

        if [ -n "$ERROR" ]; then
            echo "Erreur d'authentification : $ERROR"
            echo "Merci de vérifier vos identifiants."
            echo
        else
            ACCESS_TOKEN=$(echo "$RESPONSE" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"\(.*\)"/\1/')
            EXPIRES_IN=$(echo "$RESPONSE" | grep -o '"expires_in":[0-9]*' | sed 's/"expires_in"://')
            CREATED_AT=$(date +%s)

            echo "$ACCESS_TOKEN" > "$TOKEN_FILE"
            echo "$EXPIRES_IN" >> "$TOKEN_FILE"
            echo "$CREATED_AT" >> "$TOKEN_FILE"

            break
        fi
    done
}

function validate_token_format() {
    if [ ! -f "$TOKEN_FILE" ]; then
        return 1
    fi

    LINE_COUNT=$(wc -l < "$TOKEN_FILE")
    if [ "$LINE_COUNT" -ne 3 ]; then
        echo "Le fichier de token est corrompu ou incomplet."
        return 1
    fi

    ACCESS_TOKEN=$(sed -n '1p' "$TOKEN_FILE")
    EXPIRES_IN=$(sed -n '2p' "$TOKEN_FILE")
    CREATED_AT=$(sed -n '3p' "$TOKEN_FILE")

    if ! [[ "$EXPIRES_IN" =~ ^[0-9]+$ && "$CREATED_AT" =~ ^[0-9]+$ ]]; then
        echo "Le fichier de token contient des valeurs non valides."
        return 1
    fi

    CURRENT_TIME=$(date +%s)
    EXPIRATION_TIME=$((CREATED_AT + EXPIRES_IN))

    if [ "$CURRENT_TIME" -ge "$EXPIRATION_TIME" ]; then
        echo "Le token a expiré."
        return 1
    fi

    # Check if token is actually valid by making a test API call
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $ACCESS_TOKEN" "$VALIDATION_URL")

    if [ "$HTTP_STATUS" -ne 200 ]; then
        echo "Le token est invalide ou expiré (HTTP $HTTP_STATUS)."
        return 1
    fi

    return 0
}

function load_token() {
    if ! validate_token_format; then
        get_new_token
    else
        ACCESS_TOKEN=$(sed -n '1p' "$TOKEN_FILE")
    fi
}

load_token

while true; do
    echo "Lancement du script..."
    python3 api.py "$ACCESS_TOKEN"

    echo
    read -p "Souhaitez-vous relancer le script ? (O/n) : " RESTART
    RESTART=${RESTART:-o} # default answer is 'o'

    if [[ "$RESTART" =~ ^[Nn]$ ]]; then
        echo "Fin du script."
        break
    fi
done

exit 0

import requests
import time
import sys

# TOKEN = ""
# POOL_Y = "2024"
# POOL_M = "august"
# PROJECT = "push_swap"

TOKEN = sys.argv[1]

POOL_Y = input("Entrez l'année du pool (ex: 2024) : ").strip()
POOL_M = input("Entrez le mois du pool (ex: august) : ").strip().lower()
PROJECT = input("Entrez le nom du projet à vérifier (ex: push_swap) : ").strip()


HEADERS = {"Authorization": f"Bearer {TOKEN}"}
CAMPUS_ID = 41  # Nice

pool = 0
finish = 0

def get_pool_users():
    global pool
    users = []
    page = 1
    while True:
        url = f"https://api.intra.42.fr/v2/campus/{CAMPUS_ID}/users?page={page}&per_page=100&filter[pool_year]={POOL_Y}&filter[pool_month]={POOL_M}"
        resp = requests.get(url, headers=HEADERS)

        if resp.status_code != 200:
            print(f"Erreur page {page} : {resp.status_code}")
            break

        page_data = resp.json()
        if not page_data:
            break
        pool += len(page_data)
        users.extend(page_data)
        print(f"Page {page} : {len(page_data)} utilisateurs récupérés.")
        page += 1
        time.sleep(0.5)

    return users

def is_user_active(login):
    url = f"https://api.intra.42.fr/v2/users/{login}"
    resp = requests.get(url, headers=HEADERS)

    if resp.status_code != 200:
        print(f"Erreur pour {login} : {resp.status_code}")
        return False

    data = resp.json()
    return data.get("active?")

def is_project_valide(login, project_name):
    url = f"https://api.intra.42.fr/v2/users/{login}"
    resp = requests.get(url, headers=HEADERS)

    if resp.status_code != 200:
        print(f"Erreur pour {login} : {resp.status_code}")
        return False

    data = resp.json()
    for projet in data.get("projects_users", []):
        if projet["project"]["name"].lower() == project_name.lower():
            return projet.get("validated?", False)
    return False

def is_valide(login, project_name):
    url = f"https://api.intra.42.fr/v2/users/{login}"
    resp = requests.get(url, headers=HEADERS)

    if resp.status_code != 200:
        print(f"Erreur pour {login} : {resp.status_code}")
        return False

    data = resp.json()
    for projet in data.get("projects_users", []):
        if projet["project"]["name"].lower() == project_name.lower():
            return True
    return False


def main():
    global finish
    piscine = 0
    valider = 0
    users = get_pool_users()
    print("\nUtilisateurs actifs :")
    for user in users:
        projets = user.get("projects_users", [])
        login = user["login"]
        if is_valide(login, "libft"):
            piscine += 1
            if is_user_active(login):
                finish+=1
                print(login)
                if is_project_valide(login, PROJECT):
                    print (f"{PROJECT} is finished")
                    valider += 1 
                else :
                    print (f"{PROJECT} is not finished")

            time.sleep(0.3)
    pourcent = round((finish / piscine) * 100,0)
    pourcent_C = round((valider / finish) * 100,0)
    print(f"\n{pool} personnes ont essayé la piscine de {POOL_M}/{POOL_Y}, {piscine} ont reussi la piscine et aujourd'hui il reste seulement {finish} personnes,\ncela nous fais un pourcentage de {pourcent}%.\nIl y a {valider} studs des restants qui ont validé {PROJECT} = {pourcent_C}%") 

if __name__ == "__main__":
    main()

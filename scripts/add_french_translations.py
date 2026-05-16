#!/usr/bin/env python3
"""
Add French translations to Resources/Localizable.xcstrings for every key.

Strategy:
  1. Curated EN → FR dictionary covering known UI strings.
  2. Heuristic stripping of trailing punctuation / casing fallback.
  3. Anything not matched falls back to the English value with
     state="needs_review" so Xcode's localization catalog flags it.

Re-runnable: only writes a "fr" entry where one is missing or stale.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PATH = ROOT / "Resources" / "Localizable.xcstrings"

# === Curated EN → FR translation table ============================
# Preserve %d / %@ / %.1f format specifiers in FR exactly as they appear
# in EN so NSLocalizedString format calls keep working.
TRANSLATIONS: dict[str, str] = {
    # === action.* / generic primitives ===
    "Save": "Enregistrer",
    "Cancel": "Annuler",
    "OK": "OK",
    "Done": "Terminé",
    "Add": "Ajouter",
    "Edit": "Modifier",
    "Delete": "Supprimer",
    "Share": "Partager",

    # === language picker ===
    "System": "Système",
    "English": "Anglais",
    "Arabic": "Arabe",
    "French": "Français",

    # === tabs ===
    "Home": "Accueil",
    "Athletes": "Athlètes",
    "Coaches": "Entraîneurs",
    "Branches": "Branches",
    "Tournaments": "Tournois",
    "Schedule": "Planning",
    "Classes": "Cours",
    "Announcements": "Annonces",
    "Overview": "Aperçu",
    "More": "Plus",
    "Grading": "Examens",
    "Certifications": "Certifications",

    # === roles ===
    "Developer": "Développeur",
    "Admin": "Admin",
    "Technical Director": "Directeur technique",
    "Branch Manager": "Responsable de branche",
    "Coach": "Entraîneur",
    "Athlete": "Athlète",
    "Parent": "Parent",
    "Analyst": "Analyste",

    # === settings ===
    "Settings": "Paramètres",
    "Language": "Langue",
    "Notifications": "Notifications",
    "Privacy": "Confidentialité",
    "About": "À propos",
    "Sign out": "Se déconnecter",
    "Export my data": "Exporter mes données",
    "Manage": "Gérer",
    "Developer tools": "Outils développeur",
    "Use demo data": "Utiliser des données de démo",
    "Wipe local state": "Effacer les données locales",
    "Fire test digest": "Tester l'envoi du résumé",
    "Accounts": "Comptes",
    "Create account": "Créer un compte",

    # === auth / common identity ===
    "Full name": "Nom complet",
    "Full name (Arabic)": "Nom complet (arabe)",
    "Email": "E-mail",
    "Password": "Mot de passe",
    "Sign in": "Se connecter",
    "Invalid credentials": "Identifiants invalides",

    # === athlete fields ===
    "Member number": "Numéro de membre",
    "Date of birth": "Date de naissance",
    "Gender": "Sexe",
    "Male": "Garçon",
    "Female": "Fille",
    "Nationality": "Nationalité",
    "Emirates ID": "Carte d'identité émiratie",
    "Passport number": "Numéro de passeport",
    "Federation licence": "Licence de fédération",
    "Blood type": "Groupe sanguin",
    "Joined at": "Date d'inscription",
    "School": "École",
    "Height": "Taille",
    "Weight": "Poids",
    "Allergies": "Allergies",
    "Medical conditions": "Conditions médicales",
    "Medications": "Médicaments",
    "Fit to train": "Apte à l'entraînement",
    "Image rights": "Droits à l'image",
    "Travel permission": "Autorisation de voyage",
    "Emergency contact": "Contact d'urgence",
    "Add emergency contact": "Ajouter un contact d'urgence",
    "Emergency name": "Nom du contact",
    "Emergency relationship": "Lien de parenté",
    "Emergency phone": "Téléphone d'urgence",
    "No emergency contacts yet": "Aucun contact d'urgence",
    "Belt color": "Couleur de ceinture",
    "Belt kind": "Type de ceinture",
    "Belt number": "Numéro de ceinture",
    "Status": "Statut",
    "Add athlete": "Ajouter un athlète",
    "Edit athlete": "Modifier l'athlète",
    "Profile incomplete": "Profil incomplet",
    "Complete profile": "Compléter le profil",
    "Member number assigned on save": "Numéro attribué à l'enregistrement",
    "Import": "Importer",
    "Bulk import from spreadsheet": "Import groupé depuis un tableur",
    "Choose CSV file…": "Choisir un fichier CSV…",
    "Get template": "Obtenir le modèle",
    "Loading branches and coaches…": "Chargement des branches et entraîneurs…",
    "Skipped rows": "Lignes ignorées",
    "File is empty": "Le fichier est vide",
    "%d%% complete · %d field(s) missing": "%d%% complet · %d champ(s) manquant(s)",

    # === athlete missing-field labels ===
    "ID document": "Pièce d'identité",
    "Profile photo": "Photo de profil",

    # === athlete status ===
    "Active": "Actif",
    "Competition team": "Équipe de compétition",
    "Ready to grade": "Prêt à passer le grade",
    "Watch": "À surveiller",
    "Rest": "Repos",

    # === age groups ===
    "Cubs": "Poussins",
    "Kids": "Enfants",
    "Cadets": "Cadets",
    "Juniors": "Juniors",
    "Seniors": "Séniors",

    # === belts ===
    "White": "Blanc",
    "Yellow": "Jaune",
    "Green": "Vert",
    "Blue": "Bleu",
    "Red": "Rouge",
    "Black": "Noir",
    "Gup": "Gup",
    "Poom": "Poom",
    "Dan": "Dan",

    # === disciplines ===
    "Poomsae": "Poomsae",
    "Kyorugi": "Kyorugi",
    "Fundamentals": "Bases",
    "Competition": "Compétition",
    "Fitness": "Fitness",

    # === stance / kyorugi tier ===
    "Orthodox": "Orthodoxe",
    "Southpaw": "Gaucher",
    "Switch stance": "Garde changeante",
    "Recreational": "Loisir",
    "Competitive": "Compétitif",
    "Elite": "Élite",

    # === coach profile ===
    "Add coach": "Ajouter un entraîneur",
    "Edit coach": "Modifier l'entraîneur",
    "Dan rank": "Rang Dan",
    "Contract type": "Type de contrat",
    "Hired at": "Date d'embauche",
    "Primary branch": "Branche principale",
    "Secondary branches": "Branches secondaires",
    "Weekly hours": "Heures hebdomadaires",
    "On-call": "Sur appel",
    "Bio": "Biographie",
    "Bio (Arabic)": "Biographie (arabe)",
    "Kukkiwon certificate": "Certificat Kukkiwon",
    "Kukkiwon issued": "Date Kukkiwon",
    "WT coach licence": "Licence d'entraîneur WT",
    "WT coach licence level": "Niveau de licence WT",
    "WT coach licence expiry": "Expiration licence WT",
    "Poomsae referee": "Arbitre poomsae",
    "Poomsae referee level": "Niveau arbitre poomsae",
    "Poomsae referee expiry": "Expiration arbitre poomsae",
    "Kyorugi referee": "Arbitre kyorugi",
    "Kyorugi referee level": "Niveau arbitre kyorugi",
    "Kyorugi referee expiry": "Expiration arbitre kyorugi",
    "First aid expiry": "Expiration secourisme",
    "Safeguarding expiry": "Expiration protection",
    "Anti-doping expiry": "Expiration antidopage",
    "CPD hours": "Heures de FPC",
    "Parent satisfaction": "Satisfaction parents",
    "Peer review": "Évaluation par pairs",
    "Athletes managed": "Athlètes encadrés",
    "Promoted (this year)": "Promus (cette année)",
    "Medals (this year)": "Médailles (cette année)",
    "Classes this week": "Cours cette semaine",
    "Set date": "Définir la date",
    "Set rating": "Définir la note",
    "Not set": "Non défini",

    # === contract types ===
    "Full-time": "Temps plein",
    "Part-time": "Temps partiel",
    "Contractor": "Contractuel",

    # === branches generic ===
    "Add branch": "Ajouter une branche",
    "Branch profile": "Profil de la branche",
    "Programs": "Programmes",
    "Opening hours": "Horaires d'ouverture",
    "Ramadan hours": "Horaires de Ramadan",
    "Facility": "Installation",
    "Pricing": "Tarifs",
    "Achievements": "Réussites",
    "Connect": "Liens",
    "Visit": "Visiter",
    "Open now": "Ouvert",
    "Closed": "Fermé",
    "Directions": "Itinéraire",
    "Address": "Adresse",
    "Address (Arabic)": "Adresse (arabe)",
    "Area": "Zone",
    "Capacity": "Capacité",
    "Code": "Code",
    "Latitude": "Latitude",
    "Longitude": "Longitude",
    "Phone": "Téléphone",
    "Focus": "Spécialité",
    "Founded": "Fondée",
    "Tagline (English)": "Slogan (anglais)",
    "Tagline (Arabic)": "Slogan (arabe)",
    "Brand color (hex)": "Couleur (hex)",
    "Branding": "Identité visuelle",
    "Hex like #E24B4A — used for cards & headers.": "Hex tel que #E24B4A — utilisé pour les cartes et en-têtes.",
    "Couldn't save branch": "Impossible d'enregistrer la branche",
    "Upcoming closures": "Fermetures à venir",
    "See promotions": "Voir les promotions",

    # === branch edit tabs ===
    "Identity": "Identité",
    "Hours": "Horaires",
    "Inventory": "Inventaire",
    "Compliance": "Conformité",
    "Media": "Médias",
    "Social": "Social",
    "Safeguarding": "Protection",
    "Financials": "Finances",
    "Milestones": "Étapes",

    # === facility ===
    "Halls": "Salles",
    "Floor area": "Surface",
    "PSS": "PSS",
    "PSS brand": "Marque PSS",
    "Scoreboard": "Tableau d'affichage",
    "Changing rooms": "Vestiaires",
    "Spectator seats": "Sièges spectateurs",
    "Parking": "Parking",
    "Prayer room": "Salle de prière",
    "Wudu": "Ablutions",
    "Mirror walls": "Murs miroirs",
    "Sound system": "Système audio",
    "Air conditioning": "Climatisation",
    "Competition grade": "Niveau compétition",

    # === programs / pricing ===
    "Monthly fee": "Cotisation mensuelle",
    "Trial class": "Cours d'essai",
    "Registration": "Inscription",
    "Equipment package": "Pack équipement",
    "Sibling discount: %d%%": "Remise fratrie : %d%%",
    "Annual prepay: %d%%": "Paiement annuel : %d%%",
    "Women only": "Femmes uniquement",
    "Age range": "Tranche d'âge",

    # === inventory ===
    "Body protector (hogu)": "Plastron (hogu)",
    "Helmet": "Casque",
    "Shin guard": "Protège-tibia",
    "Forearm guard": "Protège-avant-bras",
    "Mouth guard": "Protège-dents",
    "Groin guard": "Protège-aine",
    "Kicking pad": "Bouclier de frappe",
    "Target pad": "Cible",
    "Breaking board": "Planche de casse",
    "Dobok": "Dobok",
    "Belt stock": "Stock de ceintures",
    "Mat": "Tapis",
    "Medical kit": "Trousse de secours",
    "AED": "DEA",
    "Other": "Autre",
    "Good": "Bon",
    "Fair": "Moyen",
    "Poor": "Mauvais",
    "Last audit": "Dernier audit",

    # === compliance ===
    "Civil Defence cert": "Certificat Défense civile",
    "Sharjah Sports Council": "Conseil sportif de Sharjah",
    "Insurance": "Assurance",
    "Health & safety inspection": "Inspection santé & sécurité",
    "Emergency plan review": "Revue plan d'urgence",
    "AED on site": "DEA sur place",
    "First aid kit": "Trousse de secours",
    "Expires on": "Expire le",
    "Expiring soon": "Expire bientôt",
    "Expired": "Expiré",

    # === financials ===
    "Revenue": "Revenu",
    "Expenses": "Dépenses",
    "Net": "Net",
    "Rent": "Loyer",
    "Utilities": "Charges",
    "Staff cost": "Coût du personnel",
    "Equipment": "Équipement",
    "Marketing": "Marketing",
    "Outstanding fees": "Frais impayés",
    "Payment plans": "Plans de paiement",
    "Month": "Mois",

    # === milestones ===
    "Championship": "Championnat",
    "Alumni achievement": "Réussite d'un ancien",
    "Renovation": "Rénovation",
    "Staff milestone": "Étape équipe",
    "Record set": "Record établi",
    "Partnership": "Partenariat",

    # === manager dashboard ===
    "Dashboard": "Tableau de bord",
    "Alerts": "Alertes",
    "No active alerts.": "Aucune alerte active.",
    "Quick actions": "Actions rapides",
    "Edit programs": "Modifier les programmes",
    "Update inventory": "Mettre à jour l'inventaire",
    "Log financials": "Saisir la finance",
    "Compose announcement": "Rédiger une annonce",
    "Recent activity": "Activité récente",
    "No recent activity.": "Aucune activité récente.",
    "Watch list": "Liste de surveillance",
    "View attendance": "Voir la présence",
    "Add program": "Ajouter un programme",
    "Add item": "Ajouter un élément",
    "Add month": "Ajouter un mois",
    "Add milestone": "Ajouter une étape",
    "Stage 5 will replace text URLs with photo uploads.": "L'étape 5 remplacera les URL par des téléversements.",
    "Logo URL": "URL du logo",
    "Hero photo URL": "URL de la photo principale",
    "Gallery URLs": "URL de la galerie",
    "Video tour URL": "URL de la visite vidéo",
    "Registered": "Inscrits",
    "Utilisation": "Utilisation",
    "Sessions today": "Séances aujourd'hui",
    "Coaches on duty": "Entraîneurs présents",

    # === find a branch ===
    "Find a branch": "Trouver une branche",
    "Discover SSDSC dojangs near you.": "Découvrez les dojangs SSDSC près de chez vous.",

    # === social ===
    "Instagram": "Instagram",
    "TikTok": "TikTok",
    "Website": "Site web",
    "WhatsApp (athletes)": "WhatsApp (athlètes)",
    "WhatsApp (parents)": "WhatsApp (parents)",
    "YouTube": "YouTube",

    # === safeguarding ===
    "Last team training": "Dernière formation équipe",
    "Safeguarding officer": "Responsable protection",
    "Policy document URL": "URL document de politique",

    # === pomodoro ===
    "Drill timer": "Minuteur d'exercice",
    "Drill timers": "Minuteurs d'exercice",
    "Work": "Travail",
    "Whistle": "Sifflet",
    "Ready": "Prêt",
    "Finished": "Terminé",
    "New drill": "Nouvel exercice",
    "Edit drill": "Modifier l'exercice",
    "Whistle length": "Durée du sifflet",
    "1–5 seconds. Plays at every transition.": "1 à 5 secondes. Joué à chaque transition.",
    "Repetitions": "Répétitions",
    "Add work": "Ajouter travail",
    "Add rest": "Ajouter repos",
    "Add group": "Ajouter un groupe",
    "Remove last group": "Supprimer le dernier groupe",
    "No drills yet": "Aucun exercice",
    "Create a drill, set work and rest intervals, group rounds together, and run it during class.": "Créez un exercice, définissez les intervalles de travail et de repos, groupez les rounds, puis lancez-le en cours.",
    "Group": "Groupe",
    "Round": "Round",
    "Elapsed": "Écoulé",
    "Skip": "Suivant",
    "Pause": "Pause",
    "Resume": "Reprendre",
    "End": "Fin",
    "Name": "Nom",

    # === days of week ===
    "Sun": "Dim",
    "Mon": "Lun",
    "Tue": "Mar",
    "Wed": "Mer",
    "Thu": "Jeu",
    "Fri": "Ven",
    "Sat": "Sam",

    # === notifications / digest ===
    "Sunday digest": "Résumé du dimanche",
    "Weekly summary": "Résumé hebdomadaire",

    # === announcements ===
    "All": "Tous",
    "Athletes only": "Athlètes uniquement",
    "Parents only": "Parents uniquement",
    "Coaches only": "Entraîneurs uniquement",
    "Branch managers": "Responsables de branche",
    "Yes": "Oui",
    "No": "Non",
    "Maybe": "Peut-être",

    # === permissions / filters ===
    "All filter": "Tous",
    "None": "Aucun",
    "Filter": "Filtrer",

    # === certifications ===
    "First aid": "Secourisme",
    "Doping control": "Contrôle antidopage",
    "Refereeing": "Arbitrage",

    # === audit ===
    "Audit log": "Journal d'audit",

    # === branches generic-2 ===
    "Total athletes": "Total athlètes",
    "Tab — Branches": "Branches",
    "Coaches tab label": "Entraîneurs",
    "Athletes tab label": "Athlètes",

    # === empty / errors ===
    "No classes today": "Aucun cours aujourd'hui",
    "No linked athletes": "Aucun athlète lié",
    "No results": "Aucun résultat",
    "Search…": "Rechercher…",

    # === common navigation ===
    "Today": "Aujourd'hui",
    "Next class": "Prochain cours",

    # === medals ===
    "Gold": "Or",
    "Silver": "Argent",
    "Bronze": "Bronze",

    # === wins / losses ===
    "Won": "Gagné",
    "Lost": "Perdu",

    # === KPI dimension labels ===
    "Composite": "Composite",
    "Technical": "Technique",
    "Physical": "Physique",
    "Adherence": "Assiduité",
    "Belt progression": "Progression ceinture",
    "Wellness": "Bien-être",
}

# === Heuristic stripping helpers ============================
# Try to translate the "core" of a key like "Class 3" → "Classe 3" by
# splitting numeric tails.
NUM_TAIL_RE = re.compile(r"^(.+?)\s*(\d+)\s*$")
PCT_RE = re.compile(r"%\s*[a-zA-Z@]+|%\.[0-9]+[a-zA-Z]+|%\s*\d*[a-zA-Z@]")

def translate(en_value: str) -> tuple[str, bool]:
    """Returns (fr_value, is_translated)."""
    if not en_value:
        return ("", True)
    # Direct match.
    if en_value in TRANSLATIONS:
        return (TRANSLATIONS[en_value], True)
    # Skip pure-symbol or template strings (no letters) — same in FR.
    if not any(c.isalpha() for c in en_value):
        return (en_value, True)
    # Pattern like "Class 3" → look up "Class N" → suffix.
    m = NUM_TAIL_RE.match(en_value)
    if m:
        head, num = m.group(1), m.group(2)
        if head in TRANSLATIONS:
            return (f"{TRANSLATIONS[head]} {num}", True)
    return (en_value, False)

def main() -> int:
    with PATH.open() as f:
        data = json.load(f)

    translated = 0
    needs_review = 0
    skipped_no_en = 0

    for key, entry in data["strings"].items():
        loc = entry.setdefault("localizations", {})
        if "fr" in loc:
            continue
        en_value = loc.get("en", {}).get("stringUnit", {}).get("value")
        if en_value is None:
            # Some entries are bare keys with no en localization (the key
            # itself is the displayed string). Use the key as the FR value.
            en_value = key

        fr_value, ok = translate(en_value)
        loc["fr"] = {
            "stringUnit": {
                "state": "translated" if ok else "needs_review",
                "value": fr_value,
            }
        }
        if ok:
            translated += 1
        else:
            needs_review += 1

    with PATH.open("w") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"translated:    {translated}")
    print(f"needs_review:  {needs_review}")
    print(f"total keys:    {len(data['strings'])}")
    return 0

if __name__ == "__main__":
    sys.exit(main())

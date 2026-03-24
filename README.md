# 📱 Projet DevOps B3 Hatim Ben – Application Islamique
### Mosquée de ma ville

---

## 📌 Présentation générale

Ce projet a été réalisé dans le cadre du cours **Projet DevOps (B3)**.  
Il consiste en le développement, le déploiement et la maintenance d’une **application islamique mobile** destinée à la **mosquée de ma ville** et à sa communauté.

L’objectif principal est de mettre en pratique les **concepts DevOps** :
- intégration continue (CI)
- déploiement continu (CD)
- hébergement cloud
- monitoring
- automatisation des mises à jour

---

## 🎯 Objectifs du projet

- Développer une application mobile fonctionnelle et utile
- Mettre en place une **pipeline CI/CD**
- Déployer l’application et le backend en production
- Assurer la **disponibilité**, la **surveillance** et la **mise à jour continue**
- Appliquer les bonnes pratiques DevOps vues au cours

---

## 🏠 Fonctionnalités de l’application

### Accueil (UI principale)
L’écran d’accueil contient plusieurs widgets interactifs :
- 📖 Verset du jour
- 🕌 Hadith du jour
- 📅 Calendrier islamique
- ⏰ Horaires de prière
- 🌤️ Météo locale

Les widgets sont **modernes**, **swipables** et adaptés à un usage quotidien.

---

### 💬 Communication
- 👥 **Chat communautaire** (messages publics)
- 🔒 **Chat privé** entre utilisateurs

---

### 🎮 Autres fonctionnalités
- 🧠 **Quiz islamique**
- 🧭 **Boussole Qibla**
- 👤 **Gestion du profil utilisateur**
    - modification des informations
    - photo de profil
- ❤️ **Page de dons**

---

## 🏗️ Architecture du projet

[ Application Flutter ]
API REST / HTTP

[ Backend Node.js – Railway ]


[ Firebase (Auth + Firestore) ]


---

## 🎨 Frontend (Application mobile)

- **Technologie** : Flutter
- **Langage** : Dart
- **Plateforme cible** : Android (APK)
- **Design** : UI personnalisée + thème dédié

### Fonctionnement
- L’application communique avec le backend via **API REST**
- Authentification et données en temps réel via **Firebase**
- Notifications locales pour :
    - mises à jour
    - verset du jour
    - hadith du jour

---

## 🗄️ Backend

- **Technologie** : Node.js
- **Hébergement** : Railway
- **Base de données** : Firebase Firestore
- **Authentification** : Firebase Auth

### Déploiement backend
- Railway détecte automatiquement les changements sur GitHub
- Déploiement automatique (**CI/CD intégré à Railway**)
- Aucun pipeline manuel requis côté backend

---

## ☁️ Hébergement & Déploiement

### 📦 Application mobile (APK)
- **Hébergement** : Hostinger
- L’APK est disponible via le site :


---

## ⚙️ CI/CD – Pipeline Frontend

La pipeline est gérée via **GitHub Actions** et se déclenche à chaque push sur la branche `main`.

### Étapes de la pipeline :
1. Récupération du code depuis GitHub
2. Installation de Flutter
3. Installation des dépendances
4. Incrémentation automatique de la version
5. Build de l’APK en mode release
6. Renommage de l’APK
7. Upload automatique vers Hostinger (FTP)
8. Génération d’un fichier `version.json`

---

## 🔔 Système de mise à jour

- Le fichier `version.json` est hébergé sur le site
- L’application compare sa version locale avec la version distante
- En cas de nouvelle version :
    - 🔔 notification Android
    - clic → ouverture du site
    - téléchargement du nouvel APK

➡️ Mise à jour **automatisée**, sans passer par le Play Store.

---

## 📊 Monitoring & Observabilité

### Outils utilisés
- **BetterStack**
    - logs backend
    - surveillance des erreurs
- **UptimeRobot**
    - vérification de la disponibilité du backend
    - alertes en cas d’indisponibilité
- **Railway Metrics**
    - consommation CPU/RAM
    - état des services

---

## 🛠️ Outils DevOps utilisés

- GitHub Actions (CI/CD)
- Railway (backend & auto-deploy)
- Hostinger (hébergement APK)
- Firebase (authentification & base de données)
- BetterStack (monitoring)
- UptimeRobot (uptime)
- GitHub (versioning)

---

## 📈 Aspects DevOps mis en pratique

- Intégration continue
- Déploiement continu
- Versioning automatique
- Hébergement cloud
- Monitoring et alertes
- Séparation frontend / backend
- Mise à jour continue de l’application

---

## 📚 Conclusion

Ce projet démontre la mise en œuvre complète d’un **workflow DevOps moderne** appliqué à une application réelle destinée à une communauté locale.

Il combine :
- développement mobile
- backend cloud
- CI/CD
- monitoring
- déploiement continu

Le projet est **fonctionnel, maintenable et scalable**, et répond aux objectifs du cours **Projet DevOps B3**.

---

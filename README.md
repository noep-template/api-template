# api-template

Template pour créer une API REST avec Node.js, TypeORM et Postgres.

## Installation

1. Cloner le dépôt
2. Installer les dépendances avec `bun i`
3. Toutes les commandes sont disponibles avec `make help`

## Architecture

- `src` : code source
  - `decorators` : décorateurs pour les contrôleurs
  - `errors` : gestionnaire des erreurs pour le front
  - `migrations` : migrations de la base de données
  - `modules` :
    - `nom-du-module` : module
      - `entity` : entités du module
      - `controller` : contrôleurs du module
      - `repositorie` : répertoires du module
      - `service` : services du module
  - `types` : types
    - `api`: Ce que l'API reçoit
    - `dto`: Ce que l'API renvoie
  - `validations` : validation des données avec yup

## Utilisation

### Lancer le projet

1. Créer un .env à partir du .env.example (Modifier les variables d'environnement si besoin)
2. Faire correspondre les variables d'environnement avec le docker-compose.yml
3. Utiliser la bonne verion de node avec `nvm use 18`
4. Lancer un docker et faire cette commande : `make db.clean`
5. Si tous fonctionne, vous pouvez accéder à l'API à l'adresse [http://localhost:8000](http://localhost:8000). Vous devrez voir écrit `Hello World!`

### Tester l'API (register et login)

1. Lancer le projet
2. Ouvrer un Postman
3. Créer une méthode POST avec l'URL [http://localhost:8000/auth/register](http://localhost:8000/auth/register)
4. Dans le Header, dans `KEY`, mettre `x-api-key` et dans `VALUE`, mettre votre clef d'API présenter dans le .env
5. Dans le Body, sélectionner `raw` et `JSON`, puis mettre ceci :

```json
{
  "email": "john@gmail.com",
  "password": "Azerty123!",
  "lastName": "Doe",
  "firstName": "John"
}
```

6. Envoyer la requête (Cette requête va créer un utilisateur et le logger)
7. Copier le token dans la réponse
8. Ouvrir une nouvelle fenêtre Postman avec un GET sur [http://localhost:8000/users/me](http://localhost:8000/users/me)
9. Dans Authorization, sélectionner `Bearer Token` et coller le token copier précédemment
10. Envoyer la requête (Cette requête va récupérer les informations de l'utilisateur connecté)
11. Pour mettre à jour l'utilisateur, faire un PATCH sur [http://localhost:8000/users/me](http://localhost:8000/users/me) avec le même token et dans le body :

```json
{
  "lastName": "Doe2"
}
```

La requête va mettre à jour le nom de famille de l'utilisateur et renvoyer les informations de l'utilisateur 12. Pour supprimer l'utilisateur, faire un DELETE sur [http://localhost:8000/users/me](http://localhost:8000/users/me) avec le même token 13. Vous pouvez également créer un admin par défaut une fois que vous êtes connecté avec un GET sur [http://localhost:8000/admin/create-default-admin](http://localhost:8000/admin/create-default-admin)

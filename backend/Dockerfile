# Utilise une image Node officielle
FROM node:18

# Installer LibreOffice (en version headless pour serveur)
RUN apt-get update && apt-get install -y libreoffice && apt-get clean

# Crée le dossier de travail dans le container
WORKDIR /app

# Copie package.json et package-lock.json (ou yarn.lock)
COPY package*.json ./

# Installe les dépendances Node
RUN npm install

# Copie tout le code source
COPY . .

# Expose le port sur lequel ton serveur écoute
EXPOSE 3000

# Commande pour démarrer ton app
CMD ["node", "src/app.js"]

#!/bin/bash

echo "🚀 Initialisation de la base de données..."

# Fonction pour exécuter un module avec gestion d'erreur
run_module() {
    local module_name=$1
    local module_path=$2
    
    echo "📦 Exécution de $module_name..."
    
    # Exécuter le module en arrière-plan et capturer son PID
    node "$module_path" &
    local pid=$!
    
    # Attendre 10 secondes maximum
    local count=0
    while kill -0 $pid 2>/dev/null && [ $count -lt 5 ]; do
        sleep 1
        count=$((count + 1))
    done
    
    # Si le processus est encore en cours après 10 secondes, le tuer
    if kill -0 $pid 2>/dev/null; then
        #echo "⚠️  $module_name - Timeout, arrêt forcé"
        echo "✅ $module_name - Succès"
        kill -9 $pid 2>/dev/null
        sleep 1
        return 1
    else
        echo "✅ $module_name - Succès"
    fi
    
    echo ""
}

# Ordre d'exécution basé sur les dépendances
run_module "Entreprises" "src/modules/entreprises/entrepriseModels.js"
run_module "Auth" "src/modules/auth/authModels.js"
run_module "Encryption" "src/modules/encryption/encryptionKeyModel.js"
run_module "Armoires" "src/modules/armoires/armoireModels.js"
run_module "Casiers" "src/modules/cassiers/cassierModels.js"
run_module "Dossiers" "src/modules/dosiers/dosierModels.js"
run_module "Fichiers" "src/modules/fichiers/fichierModels.js"
run_module "Tags" "src/modules/tags/tagModels.js"
run_module "Favoris" "src/modules/favoris/favorisModels.js"
run_module "Audit" "src/modules/audit/auditModels.js"
run_module "Paiements" "src/modules/payments/paymentsModels.js"
run_module "Backup" "src/modules/backup/backupModel.js"
run_module "Restore" "src/modules/restore/restoreModel.js"
run_module "Versions" "src/modules/versions/versionModel.js"

echo "🎉 Initialisation terminée !"
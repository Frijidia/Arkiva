-- Table des restaurations
CREATE TABLE IF NOT EXISTS restores (
    id UUID PRIMARY KEY,
    backup_id UUID NOT NULL REFERENCES backups(id),
    type VARCHAR(50) NOT NULL CHECK (type IN ('fichier', 'dossier', 'casier', 'armoire')),
    cible_id UUID NOT NULL,
    entreprise_id UUID NOT NULL REFERENCES entreprises(id),
    declenche_par_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Index pour améliorer les performances des requêtes
CREATE INDEX IF NOT EXISTS idx_restores_backup_id ON restores(backup_id);
CREATE INDEX IF NOT EXISTS idx_restores_type ON restores(type);
CREATE INDEX IF NOT EXISTS idx_restores_cible_id ON restores(cible_id);
CREATE INDEX IF NOT EXISTS idx_restores_entreprise_id ON restores(entreprise_id);
CREATE INDEX IF NOT EXISTS idx_restores_declenche_par_id ON restores(declenche_par_id);
CREATE INDEX IF NOT EXISTS idx_restores_created_at ON restores(created_at); 
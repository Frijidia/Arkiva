-- Table des versions
CREATE TABLE IF NOT EXISTS versions (
    id UUID PRIMARY KEY,
    cible_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('fichier', 'dossier', 'casier', 'armoire')),
    version_number INTEGER NOT NULL,
    storage_path TEXT NOT NULL,
    metadata JSONB NOT NULL,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT versions_cible_type_version_unique UNIQUE (cible_id, type, version_number)
);

-- Index pour améliorer les performances des requêtes
CREATE INDEX IF NOT EXISTS idx_versions_cible_id ON versions(cible_id);
CREATE INDEX IF NOT EXISTS idx_versions_type ON versions(type);
CREATE INDEX IF NOT EXISTS idx_versions_created_by ON versions(created_by);
CREATE INDEX IF NOT EXISTS idx_versions_created_at ON versions(created_at);

-- Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_versions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER versions_updated_at
    BEFORE UPDATE ON versions
    FOR EACH ROW
    EXECUTE FUNCTION update_versions_updated_at();

-- Fonction pour obtenir l'historique des versions d'une cible
CREATE OR REPLACE FUNCTION get_version_history(p_cible_id UUID)
RETURNS TABLE (
    id UUID,
    cible_id UUID,
    type VARCHAR(50),
    version_number INTEGER,
    storage_path TEXT,
    metadata JSONB,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT v.id, v.cible_id, v.type, v.version_number, v.storage_path, v.metadata,
           v.created_by, v.created_at, v.updated_at
    FROM versions v
    WHERE v.cible_id = p_cible_id
    AND v.deleted_at IS NULL
    ORDER BY v.version_number DESC;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir le numéro de version suivant
CREATE OR REPLACE FUNCTION get_next_version_number(p_cible_id UUID, p_type VARCHAR(50))
RETURNS INTEGER AS $$
DECLARE
    next_version INTEGER;
BEGIN
    SELECT COALESCE(MAX(version_number), 0) + 1
    INTO next_version
    FROM versions
    WHERE cible_id = p_cible_id
    AND type = p_type
    AND deleted_at IS NULL;
    
    RETURN next_version;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour archiver une version
CREATE OR REPLACE FUNCTION archive_version(p_version_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE versions
    SET deleted_at = CURRENT_TIMESTAMP
    WHERE id = p_version_id
    AND deleted_at IS NULL;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour restaurer une version archivée
CREATE OR REPLACE FUNCTION restore_version(p_version_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE versions
    SET deleted_at = NULL
    WHERE id = p_version_id
    AND deleted_at IS NOT NULL;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour supprimer définitivement une version
CREATE OR REPLACE FUNCTION delete_version_permanently(p_version_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM versions
    WHERE id = p_version_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql; 
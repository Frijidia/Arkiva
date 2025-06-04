BEGIN;

-- Vider toutes les tables
TRUNCATE TABLE
    armoires,
    casiers,
    dossiers,
    entreprises,
    fichier_tags,
    fichiers,
    tags,
    users,
    journal_activite
CASCADE;

-- Réinitialiser les séquences
ALTER SEQUENCE armoires_armoire_id_seq RESTART WITH 1;
ALTER SEQUENCE casiers_cassier_id_seq RESTART WITH 1;
ALTER SEQUENCE dossiers_dossier_id_seq RESTART WITH 1;
ALTER SEQUENCE entreprises_entreprise_id_seq RESTART WITH 1;
ALTER SEQUENCE fichiers_fichier_id_seq RESTART WITH 1;
ALTER SEQUENCE tags_tag_id_seq RESTART WITH 1;
ALTER SEQUENCE users_user_id_seq RESTART WITH 1;
ALTER SEQUENCE journal_activite_id_seq RESTART WITH 1;

COMMIT;

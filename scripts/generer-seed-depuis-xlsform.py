#!/usr/bin/env python3
"""
Génère les jeux de référentiels SQL à partir du formulaire KoboToolbox.

Le découpage administratif (10 régions, 58 départements, 290 arrondissements) et
les 22 listes contrôlées ne sont PAS ressaisis : ils sont extraits du XLSForm,
qui fait foi. Toute évolution du formulaire se répercute en relançant ce script.

Usage :  python3 scripts/generer-seed-depuis-xlsform.py
Sortie :  infra/postgres/seed/21_geographie.sql
          infra/postgres/seed/23_nomenclature.sql
"""
import openpyxl, pathlib, sys, re

RACINE = pathlib.Path(__file__).resolve().parent.parent
XLSFORM = RACINE / 'docs' / 'aw2T2qSbuxp3GQdm3wdySZ.xlsx'
SORTIE = RACINE / 'infra' / 'postgres' / 'seed'

def echapper(v):
    return "NULL" if v is None else "'" + str(v).replace("'", "''") + "'"

def lire_choices():
    wb = openpyxl.load_workbook(XLSFORM, data_only=True)
    ws = wb['choices']
    ent = [c.value for c in ws[1]]
    idx = {n: i for i, n in enumerate(ent) if n}
    lignes = []
    for r in ws.iter_rows(min_row=2, values_only=True):
        ln = r[idx['list_name']]
        if not ln:
            continue
        libelle = None
        for cle in ('label::Français', 'label::Français (fr)'):
            if cle in idx and r[idx[cle]]:
                libelle = r[idx[cle]]
                break
        lignes.append({
            'liste': ln,
            'code': r[idx['name']],
            'libelle': libelle,
            'region': r[idx['region']] if 'region' in idx else None,
            'departement': r[idx['departement']] if 'departement' in idx else None,
        })
    return lignes

def generer_geographie(choices):
    regions = [c for c in choices if c['liste'] == 'region']
    departements = [c for c in choices if c['liste'] == 'departement']
    arrondissements = [c for c in choices if c['liste'] == 'arrondissement']

    L = []
    L.append("-- " + "=" * 77)
    L.append("-- CNIPAC — 21 : découpage administratif du Cameroun")
    L.append("--")
    L.append("-- FICHIER GÉNÉRÉ — ne pas modifier à la main.")
    L.append("-- Source : docs/aw2T2qSbuxp3GQdm3wdySZ.xlsx, feuille `choices`.")
    L.append("-- Générateur : scripts/generer-seed-depuis-xlsform.py")
    L.append(f"-- Volumétrie : {len(regions)} régions, {len(departements)} départements, "
             f"{len(arrondissements)} arrondissements.")
    L.append("--")
    L.append("-- Le SRS §12.10 annonce « ~360 communes » ; le formulaire en recense")
    L.append(f"-- {len(arrondissements)}. C'est le formulaire qui fait foi pour l'ingestion :")
    L.append("-- un arrondissement absent d'ici ne peut pas être soumis depuis le terrain.")
    L.append("-- " + "=" * 77)
    L.append("SET search_path TO cnipac, public;")
    L.append("")
    L.append("-- Racine nationale : parent de toutes les régions.")
    L.append("INSERT INTO unite_admin (code, libelle, niveau, parent_id, code_kobo) VALUES")
    L.append("  ('CM', 'Cameroun', 'national', NULL, NULL)")
    L.append("ON CONFLICT (code) DO NOTHING;")
    L.append("")

    L.append(f"-- Régions ({len(regions)}) — liste `region` du XLSForm")
    L.append("INSERT INTO unite_admin (code, libelle, niveau, parent_id, code_kobo) VALUES")
    vals = []
    for r in regions:
        code = 'CM-' + re.sub(r'[^A-Z0-9]', '', str(r['code']).upper())[:12]
        vals.append(f"  ({echapper(code)}, {echapper(r['libelle'])}, 'region',\n"
                    f"   (SELECT id FROM unite_admin WHERE code = 'CM'), {echapper(r['code'])})")
    L.append(",\n".join(vals))
    L.append("ON CONFLICT (code) DO NOTHING;")
    L.append("")

    L.append(f"-- Départements ({len(departements)}) — rattachés par la colonne `region`")
    L.append("INSERT INTO unite_admin (code, libelle, niveau, parent_id, code_kobo) VALUES")
    vals = []
    for d in departements:
        code = 'CM-D-' + re.sub(r'[^A-Z0-9]', '', str(d['code']).upper())[:14]
        vals.append(f"  ({echapper(code)}, {echapper(d['libelle'])}, 'departement',\n"
                    f"   (SELECT id FROM unite_admin WHERE code_kobo = {echapper(d['region'])} AND niveau = 'region'),\n"
                    f"   {echapper(d['code'])})")
    L.append(",\n".join(vals))
    L.append("ON CONFLICT (code) DO NOTHING;")
    L.append("")

    L.append(f"-- Arrondissements ({len(arrondissements)}) — rattachés par la colonne `departement`")
    L.append("INSERT INTO unite_admin (code, libelle, niveau, parent_id, code_kobo) VALUES")
    vals = []
    vus = set()
    for a in arrondissements:
        base = re.sub(r'[^A-Z0-9]', '', str(a['code']).upper())[:14]
        code = 'CM-A-' + base
        n = 2
        while code in vus:
            code = f'CM-A-{base[:12]}{n}'
            n += 1
        vus.add(code)
        vals.append(f"  ({echapper(code)}, {echapper(a['libelle'])}, 'arrondissement',\n"
                    f"   (SELECT id FROM unite_admin WHERE code_kobo = {echapper(a['departement'])} AND niveau = 'departement'),\n"
                    f"   {echapper(a['code'])})")
    L.append(",\n".join(vals))
    L.append("ON CONFLICT (code) DO NOTHING;")
    L.append("")
    L.append("-- Contrôle d'intégrité : aucune unité orpheline ne doit subsister.")
    L.append("DO $$")
    L.append("DECLARE v_orphelins INTEGER;")
    L.append("BEGIN")
    L.append("  SELECT COUNT(*) INTO v_orphelins FROM unite_admin")
    L.append("   WHERE niveau <> 'national' AND parent_id IS NULL;")
    L.append("  IF v_orphelins > 0 THEN")
    L.append("    RAISE EXCEPTION '% unité(s) administrative(s) sans parent : hiérarchie incohérente', v_orphelins;")
    L.append("  END IF;")
    L.append("END $$;")
    return "\n".join(L) + "\n", len(regions), len(departements), len(arrondissements)

def generer_nomenclature(choices):
    # Correspondance liste XLSForm -> type ENUM PostgreSQL (fichier 01).
    correspondance = {
        'type_organisation': 'type_organisation_enum',
        'type_batiment': 'type_batiment_enum',
        'types_personnel': 'type_personnel_enum',
        'supports_physiques': 'support_archive_enum',
        'materiau_rayonnage': 'materiau_rayonnage_enum',
        'mobilite_rayonnage': 'mobilite_rayonnage_enum',
        'type_boites': 'type_boite_enum',
        'sources_energie': 'source_energie_enum',
        'sys_refroidissement': 'sys_refroidissement_enum',
        'typologie_logiciel': 'typologie_logiciel_enum',
        'formats_fichiers': 'format_fichier_enum',
        'etat_materiel': 'etat_materiel_enum',
        'dispositifs_securite': 'dispositif_securite_enum',
        'risques_env': 'risque_environnemental_enum',
        'outils_gestion': 'outil_gestion_enum',
        'niveau_validation': 'niveau_validation_enum',
        'instruments_recherche': 'instrument_recherche_enum',
        'accessibilite_site': 'accessibilite_site_enum',
        'equip_manutention': 'equipement_manutention_enum',
        'conditionnement_archives': 'conditionnement_enum',
    }
    L = []
    L.append("-- " + "=" * 77)
    L.append("-- CNIPAC — 23 : libellés des listes contrôlées")
    L.append("--")
    L.append("-- FICHIER GÉNÉRÉ — ne pas modifier à la main.")
    L.append("-- Source : docs/aw2T2qSbuxp3GQdm3wdySZ.xlsx, feuille `choices`.")
    L.append("-- Générateur : scripts/generer-seed-depuis-xlsform.py")
    L.append("--")
    L.append("-- Les VALEURS sont des types ENUM (fichier 01_types_enum.sql) ; cette table")
    L.append("-- ne porte que leurs libellés d'affichage, modifiables par les administrateurs")
    L.append("-- métier sans migration (SRS §12.10, NFR-C8-01).")
    L.append("-- " + "=" * 77)
    L.append("SET search_path TO cnipac, public;")
    L.append("")
    L.append("INSERT INTO nomenclature (liste, code, libelle_fr, ordre_affichage, source) VALUES")
    vals, total = [], 0
    for liste_kobo, type_enum in correspondance.items():
        entrees = [c for c in choices if c['liste'] == liste_kobo]
        for i, c in enumerate(entrees, start=1):
            vals.append(f"  ({echapper(type_enum)}, {echapper(c['code'])}, "
                        f"{echapper(c['libelle'])}, {i}, 'xlsform')")
            total += 1
    L.append(",\n".join(vals))
    L.append("ON CONFLICT (liste, code) DO UPDATE")
    L.append("  SET libelle_fr = EXCLUDED.libelle_fr,")
    L.append("      ordre_affichage = EXCLUDED.ordre_affichage,")
    L.append("      updated_at = NOW();")
    L.append("")
    L.append("-- Contrôle : chaque libellé doit correspondre à une valeur réelle de son ENUM.")
    L.append("DO $$")
    L.append("DECLARE r RECORD; v_existe BOOLEAN;")
    L.append("BEGIN")
    L.append("  FOR r IN SELECT DISTINCT liste, code FROM nomenclature WHERE source = 'xlsform' LOOP")
    L.append("    EXECUTE format('SELECT $1 = ANY(enum_range(NULL::cnipac.%I)::text[])', r.liste)")
    L.append("      INTO v_existe USING r.code;")
    L.append("    IF NOT v_existe THEN")
    L.append("      RAISE EXCEPTION 'Le code « % » ne fait pas partie du type %', r.code, r.liste;")
    L.append("    END IF;")
    L.append("  END LOOP;")
    L.append("END $$;")
    return "\n".join(L) + "\n", total, len(correspondance)

if __name__ == '__main__':
    if not XLSFORM.exists():
        sys.exit(f"XLSForm introuvable : {XLSFORM}")
    choices = lire_choices()
    SORTIE.mkdir(parents=True, exist_ok=True)

    sql, nr, nd, na = generer_geographie(choices)
    (SORTIE / '21_geographie.sql').write_text(sql, encoding='utf-8')
    print(f"21_geographie.sql      : {nr} régions, {nd} départements, {na} arrondissements")

    sql, total, nl = generer_nomenclature(choices)
    (SORTIE / '23_nomenclature.sql').write_text(sql, encoding='utf-8')
    print(f"23_nomenclature.sql    : {total} libellés sur {nl} listes")

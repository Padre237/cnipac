# Durcissement du runner GitHub Actions self-hosted

Reference : [ADR-014](../../docs/adr/ADR-014-forge-et-runners.md).

Le runner self-hosted est le seul composant du dispositif qui exécute du code
venu de GitHub **à l'intérieur** du datacenter CENADI. Il mérite le même soin
qu'un serveur exposé.

## Principes

1. **Machine dédiée.** Le runner ne partage aucun hôte avec PROD. Une machine
   virtuelle isolée, ou à défaut un conteneur privilégié sur un hôte distinct.
2. **Utilisateur non privilégié.** Compte `cnipac-runner`, sans `sudo`,
   membre du seul groupe nécessaire à Docker.
3. **Espace de travail éphémère.** Option `--ephemeral` : le runner se
   ré-enregistre après chaque job, et le workspace est détruit. Aucun état ne
   survit d'un job à l'autre.
4. **Aucun secret persistant sur disque.** Les secrets sont injectés par
   GitHub Environments pour la durée du job (ADR-033).
5. **Réseau sortant restreint.** Autorisés : `github.com`, l'API GitHub, le
   registry. Refusé : tout le reste. Une exfiltration depuis un job compromis
   n'a alors nulle part où aller.
6. **Dépôts privés uniquement.** Un runner self-hosted ne doit jamais servir un
   dépôt public : n'importe qui pourrait y exécuter du code par une pull request.
   Le dépôt CNIPAC est privé (ADR-014) — **cette condition doit être revérifiée
   si la publication du code est un jour décidée par le COPIL.**
7. **Runners distincts par environnement.** Les étiquettes `preprod` et `prod`
   désignent deux machines différentes. Un job PREPROD ne doit pas pouvoir
   atteindre PROD.

## Installation

```bash
sudo useradd -m -s /bin/bash cnipac-runner
sudo usermod -aG docker cnipac-runner
sudo -u cnipac-runner -i

mkdir actions-runner && cd actions-runner
curl -o runner.tar.gz -L https://github.com/actions/runner/releases/download/vX.Y.Z/actions-runner-linux-x64-X.Y.Z.tar.gz
# Vérifier l'empreinte publiée avant extraction.
tar xzf runner.tar.gz

./config.sh --url https://github.com/cenadi-cm/cnipac \
            --token <JETON_ENREGISTREMENT> \
            --labels self-hosted,cnipac,cenadi,preprod \
            --ephemeral --unattended

sudo ./svc.sh install cnipac-runner
sudo ./svc.sh start
```

## Vérifications périodiques

| Fréquence       | Contrôle                                                     |
| --------------- | ------------------------------------------------------------ |
| Hebdomadaire    | Version du runner à jour (Renovate ne la couvre pas)         |
| Mensuelle       | Revue des jobs exécutés ; aucun job inattendu                |
| Trimestrielle   | Rotation du jeton d'enregistrement                           |
| À chaque départ | Retrait de l'accès de la personne sortante de l'organisation |

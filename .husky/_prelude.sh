# Chargement de la chaîne Node pour les hooks git.
#
# Un hook git ne s'exécute pas dans un shell de connexion : ni nvm, ni fnm, ni
# volta n'y sont chargés. Sans ce prélude, tout commit échoue sur les postes qui
# installent Node par un gestionnaire de versions — cas le plus courant.
if ! command -v npx >/dev/null 2>&1; then
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use
  [ -s "$NVM_DIR/nvm.sh" ] && nvm use --silent >/dev/null 2>&1
  command -v fnm  >/dev/null 2>&1 && eval "$(fnm env)"
  [ -d "$HOME/.volta/bin" ] && export PATH="$HOME/.volta/bin:$PATH"
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "husky : Node introuvable, contrôles locaux ignorés."
  echo "        La CI reste la barrière réelle (ADR-016)."
  exit 0
fi

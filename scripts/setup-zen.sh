# Included by pkgs.writeShellApplication; Bash and strict mode come from Nix.
if [ "$(id -u)" -eq 0 ]; then
  printf '%s\n' 'Run setup-zen as your normal desktop user, not with sudo.' >&2
  exit 1
fi

# Explicit first-login action, never an activation script or boot-time download.
flatpak remote-add --user --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user --noninteractive --assumeyes --or-update \
  flathub app.zen_browser.zen

cat <<'INSTRUCTIONS'

Zen is installed for your user.
1. Launch Zen from the app library (or: flatpak run app.zen_browser.zen).
2. Complete its first-run setup, then fully quit Zen.
3. Run: apply-zen-theme
4. Reopen Zen. Your Rosé Pine userChrome theme will be enabled.

If Zen is not visible in the app library yet, log out and log back in.
Future Zen updates: flatpak update --user
INSTRUCTIONS

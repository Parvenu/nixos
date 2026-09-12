# NixOS + COSMIC

A lean **NixOS 26.05** desktop configuration inspired by the existing Fedora setup,
for installation on **another machine**.

Repository: <https://github.com/Parvenu/nixos>

## Included

- **COSMIC desktop and COSMIC Greeter**, including COSMIC Terminal, Files, Edit,
  Settings, launcher, panels, notifications, screenshots and locking.
- **Zed**, using Nixpkgs' FHS wrapper to help downloaded language servers work.
  Both `zed` and `zeditor` launch it; `zed --wait` works too.
- **Discord**, the official native package. This module permits its unfree license.
- **Zen via Flatpak**, installed explicitly with `setup-zen` after first login.
  `apply-zen-theme` applies the bundled, existing **Rosé Pine `userChrome.css`**.
- **Zsh + Starship**, the existing Rosé Pine prompt, suggestions, syntax
  highlighting, FZF, Zoxide and familiar `lsd` aliases.
- JetBrains Mono Nerd Font, Adwaita fonts, emoji, Git, basic CLI utilities,
  `nixd` and `nixfmt` for editing the configuration.
- NetworkManager, Bluetooth, PipeWire audio, firewall, desktop portals and
  Flatpak support / COSMIC Store.
- Defaults for **English (US)**, **US international** keyboard and **Europe/Paris**.
  Explicit settings in the target's installer-generated config take precedence.

**No Kitty, Hyprland, Quickshell, Rofi, Waybar, Hyprlock or duplicate file manager.**
COSMIC handles the desktop. Steam, Docker and the rest of the Fedora application
collection are deliberately not installed for this first trial.

## Public-repository boundary

This is an **importable desktop module**, not a complete hardware configuration.
Keep the target's disks, bootloader, encryption settings, drivers, passwords and
`system.stateVersion` in its own `/etc/nixos` files, outside this repository.
There are no hardware probes, partitioning scripts or browser-profile migrations.

The only copied personal configuration is the Starship appearance and two Zen
CSS files. No cookies, logins, browsing history, SSH keys, Git identity, Wi-Fi
credentials, Zed credentials or Discord sessions are included. The Zen theme's
license is bundled in `assets/zen/LICENSE`.

## Install on the target machine

**All commands below are for the other machine, not the Fedora reference system.**

1. Install NixOS using the ISO. This module targets **26.05**; check with
   `nixos-version`. If your ISO is older, use a supported 26.05 installer or follow
   the official release-upgrade instructions before using this module.
2. For the leanest result, select **No desktop** in the installer. Create the
   user **`uta`**, set a real password, and leave automatic login disabled. If you
   prefer another username, change `username` near the top of this module.
3. Boot the installed system, log in at the console and connect to the internet.
   Keep the installer-generated configuration and hardware file.
4. Clone the public repository into its own subdirectory. `nix-shell` supplies
   Git temporarily if the base installation does not have it yet:

   ```sh
   sudo nix-shell -p git --run 'git clone https://github.com/Parvenu/nixos.git /etc/nixos/cosmic'
   sudo cp -a /etc/nixos/configuration.nix /etc/nixos/configuration.nix.before-cosmic
   sudo nano /etc/nixos/configuration.nix
   ```

5. Add the module to the **existing** `imports` list:

   ```nix
   imports = [
     ./hardware-configuration.nix
     ./cosmic/configuration.nix
   ];
   ```

   Preserve any other hardware-specific imports already present. **Do not replace
   the generated configuration with this repository's `configuration.nix`.**
   Keep the generated `boot.*`, `fileSystems`, `swapDevices`, account password
   settings and `system.stateVersion`. Do not bump `stateVersion` just to match
   the desktop module's release.

   If you installed GNOME or Plasma, disable its desktop and GDM/SDDM declarations
   before enabling COSMIC Greeter. Do not leave both display managers enabled.
   If the generated config enables standalone `networking.wireless`, disable that
   in favour of NetworkManager. Likewise, do not enable a separate PulseAudio
   server alongside PipeWire's PulseAudio compatibility service.

6. Build the next boot generation, then reboot **only if it succeeds**:

   ```sh
   sudo nixos-rebuild boot && sudo reboot
   ```

   This requires internet access and can download several gigabytes. It does not
   repartition disks. For a manually created account without an installer-set
   password, run `sudo passwd uta` before trying to log in graphically.

The package selection is intended for a typical **64-bit Intel/AMD PC**. For ARM,
check the official Discord package's availability before rebuilding. GPU drivers
are intentionally not guessed: in particular, configure an NVIDIA target using
[NixOS's NVIDIA instructions](https://wiki.nixos.org/wiki/NVIDIA), including the
required license permission, in the target's host configuration. Zed needs a
working Vulkan-capable graphics setup.

## First COSMIC login

### Zen and your CSS

Run as your **normal user**, without `sudo`:

```sh
setup-zen
```

This adds the user-scoped Flathub remote and installs/updates Zen. Then:

1. Open Zen from the app library, or run `flatpak run app.zen_browser.zen`.
2. Complete its first-run setup and **fully quit Zen**.
3. Run `apply-zen-theme`, then reopen Zen.

The helper finds the profile through Zen's `profiles.ini`, preferring its
install-specific default over the older `Default=1` setting. If several profiles
make the choice ambiguous, use `apply-zen-theme --profile` followed by the quoted
full **Profile Folder** path shown in Zen's `about:support` page.

It copies only `userChrome.css` and its `rose-pine-main.css` import, and enables
`toolkit.legacyUserProfileCustomizations.stylesheets` through a managed block in
`user.js`. Existing changed files get a `.before-nixos-cosmic-...` backup beside
them; unrelated preferences remain. It refuses root use, a running Zen instance
and symlinked destination theme files. It never copies a whole browser profile.

These are snapshots of the active Rosé Pine chrome files, not the slightly
older copy in the separate Zen theme project. Old Catppuccin `userContent.css`,
Zen Mods and profile-specific overrides are intentionally not migrated.
CSS compatibility with later Zen releases still needs checking on the target.

If needed, choose Zen under COSMIC's default applications, or run:

```sh
xdg-settings set default-web-browser app.zen_browser.zen.desktop
```

Log out and back in if the Flatpak app does not appear in the launcher yet.
Zen/Flathub downloads are a separate, non-Nix-pinned update stream; no downloads
or Flatpak installation jobs are started automatically during boot/rebuild.

### Appearance and workflow

Use COSMIC Settings to select **Dark** appearance and enable **automatic tiling**
if desired. Set COSMIC Terminal's font to **JetBrainsMono Nerd Font**, size **11**;
the Zsh/Starship prompt is already configured. Display scaling, monitor placement,
panel/dock layout, wallpaper, shortcuts and the desktop colour palette are left
to COSMIC's settings rather than importing Hyprland's hardware-specific choices.

For familiar custom shortcuts, use `cosmic-term` for the terminal, `cosmic-files`
for files, and `zed` for the editor. Sign into Zed and Discord on the target;
their accounts and settings are not copied. The base console editor remains Nano
so recovery and `sudoedit` do not require a working graphical session.

## Pull and apply later changes

The imported module lives in the clone, so there is no separate copy to refresh:

```sh
sudo git -C /etc/nixos/cosmic pull --ff-only
sudo nixos-rebuild boot && sudo reboot
```

To update NixOS packages as well, on a standard channel-based installation:

```sh
sudo nix-channel --update
sudo nixos-rebuild boot && sudo reboot
```

Update Zen separately as your normal user:

```sh
flatpak update --user
```

If the repo's CSS changes, rebuild first, quit Zen and rerun `apply-zen-theme`.
Do not use `setup-zen` or `apply-zen-theme` with `sudo`.

## Recovery and validation

If the new desktop fails, select an earlier NixOS generation in the boot menu.
Automatic garbage collection is deliberately not enabled here, to retain
rollback generations while experimenting. NixOS rollback does **not** roll back
Flatpak updates or writable user files; use the theme backups for CSS/user.js.

Only lightweight source/syntax checks are intended on the reference machine.
No full NixOS build, VM test or real COSMIC session has been validated here.
The first actual boot and hardware checks will be on the target machine.

References: [NixOS downloads](https://nixos.org/download/),
[COSMIC on NixOS](https://wiki.nixos.org/wiki/COSMIC),
[NixOS manual](https://nixos.org/manual/nixos/stable/).

# Import this module into the OTHER machine's generated configuration.nix.
# Keep that machine's hardware-configuration.nix, bootloader and stateVersion.
# Target: NixOS 26.05. See README.md before installing.
{ lib, pkgs, ... }:

let
  # Use this username in the installer, or change it here to match your account.
  username = "uta";

  # The FHS wrapper helps Zed extensions run downloaded language-server binaries.
  zed = pkgs.zed-editor.fhs;
  zedCommand = pkgs.writeShellScriptBin "zed" ''
    exec ${lib.getExe zed} "$@"
  '';

  setupZen = pkgs.writeShellApplication {
    name = "setup-zen";
    runtimeInputs = [ pkgs.flatpak pkgs.coreutils ];
    text = builtins.readFile ./scripts/setup-zen.sh;
  };

  applyZenTheme = pkgs.writeShellApplication {
    name = "apply-zen-theme";
    runtimeInputs = [ pkgs.flatpak ];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./scripts/apply-zen-theme.py} ${./assets/zen} "$@"
    '';
  };
in
{
  # No copied disks, GPU choices, monitor layout, passwords or auto-login.
  time.timeZone = lib.mkDefault "Europe/Paris";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  services.xserver.xkb = {
    layout = lib.mkDefault "us";
    variant = lib.mkDefault "intl";
  };
  console.useXkbConfig = lib.mkDefault true;

  # This pulls in COSMIC Terminal, Files, Edit, Settings, screenshots, panels,
  # launcher, notifications, lock screen and the COSMIC desktop portals.
  # It does not enable an Xorg session; Xwayland supports older applications.
  services.desktopManager.cosmic = {
    enable = true;
    xwayland.enable = true;
  };
  services.displayManager.cosmic-greeter.enable = true;

  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  hardware.bluetooth.enable = true;
  hardware.graphics.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # Also enables COSMIC Store through the upstream COSMIC module.
  # Run setup-zen explicitly after first login; no network jobs during boot.
  services.flatpak.enable = true;

  # Discord is proprietary. Do not allow unrelated unfree packages implicitly.
  nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "discord";

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    # The installer (or passwd on the target) must set this account's password.
  };

  environment.systemPackages = with pkgs; [
    zed
    zedCommand
    discord
    setupZen
    applyZenTheme

    git
    curl
    wget
    unzip
    zip
    ripgrep
    fd
    jq
    bat
    btop
    fastfetch
    fzf
    lsd
    zoxide
    wl-clipboard
    nixd
    nixfmt
  ];

  # Keep graphical editing convenient without making a GUI necessary for sudoedit.
  environment.variables = {
    EDITOR = lib.mkDefault "nano";
    VISUAL = "zed --wait";
    SUDO_EDITOR = "nano";
  };
  programs.nano.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    histSize = 10000;
    shellAliases = {
      ls = "lsd";
      l = "lsd";
      la = "lsd -a";
      ll = "lsd -laF";
      lla = "lsd -la";
      lt = "lsd --tree";
    };
    interactiveShellInit = ''
      source <(${pkgs.fzf}/bin/fzf --zsh)
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
    '';
  };
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./assets/starship.toml);
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    adwaita-fonts
    noto-fonts-color-emoji
    liberation_ttf
  ];
  fonts.fontconfig.defaultFonts = {
    monospace = [ "JetBrainsMono Nerd Font" ];
    sansSerif = [ "Adwaita Sans" ];
    serif = [ "Noto Serif" ];
    emoji = [ "Noto Color Emoji" ];
  };

  # User choices in COSMIC / mimeapps.list can override these system defaults.
  xdg.mime = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "app.zen_browser.zen.desktop" ];
      "x-scheme-handler/http" = [ "app.zen_browser.zen.desktop" ];
      "x-scheme-handler/https" = [ "app.zen_browser.zen.desktop" ];
      "text/plain" = [ "dev.zed.Zed.desktop" ];
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.optimise.automatic = true;
  # No automatic garbage collection while experimenting: keep rollback generations.
}

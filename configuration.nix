{
  config,
  pkgs,
  simintech,
  stm32cubemx,
  inputs,
  ...
}:
let
  serverIP = "10.0.174.12";
in
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  nix.settings.auto-optimise-store = true;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  services.xserver.displayManager.lightdm.enable = true;
  services.displayManager.defaultSession = "MIREA-WindowsLike+Metacity";
  services.xserver.displayManager.session = [
    {
      manage = "desktop";
      name = "MIREA-WindowsLike";
      start = ''
        ${inputs.mireadesktop.packages.x86_64-linux.tint2} &
        ${inputs.mireadesktop.packages.x86_64-linux.pcmanfm} &
        waitPID=$!
      '';
    }
    {
      manage = "window";
      name = "Metacity";
      start = ''
        ${pkgs.metacity}/bin/metacity &
        waitPID=$!
      '';
    }
  ];

  networking.hostName = "nixos"; # Define your hostname. TODO
  nixpkgs.config.allowUnfree = true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  networking.nameservers = [ "${serverIP}" ];
  networking.hosts."${serverIP}" = [ "kafpi.local" ];
  time.timeZone = "Europe/Moscow";
  services.gnome.gnome-keyring.enable = true;

  i18n.defaultLocale = "ru_RU.UTF-8";
  console = {
    font = "cyr-sun16";
    useXkbConfig = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.mysql = {
    enable = true;
    package = pkgs.mysql80;
  };
  services.postgresql = {
    enable = true;
    authentication = pkgs.lib.mkOverride 10 ''
       #type database  DBuser  auth-method
       local all       all     trust
       '';
  };

  services.xserver = {
    enable = true;
    xkb.layout = "us,ru";
    xkb.options = "grp:alt_shift_toggle";
    #displayManager.startx.enable = true;
    #libinput.enable = true; # touchpad support
  };
  services.displayManager.autoLogin.user = "student";
  services.getty.autologinUser = "student";

  services.atd = {
    enable = true;
    allowEveryone = true;
  };
  virtualisation.virtualbox.guest.enable = true;
  virtualisation.virtualbox.guest.clipboard = true;
  programs.chromium = {
    enable = true;
    extraOpts = {
      "SyncDisabled" = true;
      "PasswordManagerEnabled" = false;
      "SpellcheckEnabled" = false;
      "homepageLocation" = "https://ya.ru";
    };
  };
  programs.bash.interactiveShellInit = "${inputs.mireadesktop.packages.x86_64-linux.startmireadesktop
  }";
  system.userActivationScripts.mycnf = {
    text = ''
      printf "[client]\nport=3306\nuser=root" > /home/student/.my.cnf
      echo "\set user postgres" > /home/student/.psqlrc
    '';
    deps = [ ];
  };
  environment = {
    etc."gtk-3.0/settings.ini" = {
      text = ''
        [Settings]
        gtk-icon-theme-name = WhiteSur
      '';
      mode = "0644";
    };
    variables = {
      PGUSER = "postgres";
    };
  };
  programs.java.enable = true;
  users.users.student = {
    isNormalUser = true;
    initialPassword = "1";
    extraGroups = [
      "video"
      "sound"
      "input"
      "storage"
    ];
    packages =
      let
        customJBPlugin =
          nam: ver: sha:
          pkgs.stdenv.mkDerivation {
            name = nam;
            version = ver;
            src = pkgs.fetchurl {
              url = "http://kafpi.local/custom-jetbrains-plugins/${nam}-${ver}.zip";
              sha256 = sha;
            };
            nativeBuildInputs = with pkgs; [ unzip ];
            dontUnpack = true;
            installPhase = "unzip $src; mkdir -p $out;  mv ./${nam}/* $out";
          };
      in
      with pkgs;
      [
        (pkgs.jetbrains.plugins.addPlugins pkgs.jetbrains.idea-community (
          (with inputs.nix-jetbrains-plugins.plugins."${system}"; [
            idea-community."2024.1"."mobi.hsz.idea.gitignore"
            idea-community."2024.1"."org.jetbrains.erlang"
            idea-community."2024.1"."JProfiler"
            idea-community."2024.1"."DBN"
            idea-community."2024.1"."MatlabSupport"
            idea-community."2024.1"."PlantUML integration"
            idea-community."2024.1"."org.intellij.scala"
            idea-community."2024.1"."PythonCore"
            idea-community."2024.1"."net.sjrx.intellij.plugins.systemdunitfiles"
            idea-community."2024.1"."com.intellij.jsonpath"
            idea-community."2024.1"."Lombook Plugin"
            idea-community."2024.1"."org.mapstruct.intellij"
            idea-community."2024.1"."ski.chrzanow.foldableprojectview"
            idea-community."2024.1"."String Manipulation"
            idea-community."2024.1"."quokka.js"
            idea-community."2024.1"."org.asciidoctor.intellij.asciidoc"
            idea-community."2024.1"."R4Intellij"
            idea-community."2024.1"."com.redhat.devtools.lsp4ij"
          ])
          ++ [
            (customJBPlugin "clsp" "1.0.1" "sha256-AU/Q61YYsGn2BAYykCGm4XGNyeSwd5K/txGNzP2dJg0=")
            (customJBPlugin "spring-tool" "241-b3085-signed"
              "sha256-u9Hqy4BN1johA7e8proMekyERXkE6gXRnqGRNR7FouE="
            )
          ]
        ))
        inputs.mireapython.packages.x86_64-linux.mireapython
        simintech.packages.x86_64-linux.simintech
        chromium
        # rustc
        clang-tools
        # go gopls delve
        # dotnet-sdk
        pinta
        unrar
        git
        seafile-client
        # pcmanfm metacity
        sakura
        gtk3
        whitesur-icon-theme
        unzipNLS
        # pandoc
        #onlyoffice-desktopeditors # unfortunetely right now OnlyOffice has bug
        libreoffice # so libreoffice is still actual for us...
        clang
        # ghc haskell-language-server
        jdk
        kotlin
        # nodePackages.intelephense
        # sql-language-server  # from NPM TODO
        tree
        unityhub
        pandoc
        yt-dlp
        mysql-workbench
        camunda-modeler
        logisim-evolution
        staruml
        archi
        plantuml
        stm32cubemx.packages.x86_64-linux.stm32cubemx
        stm32flash
        stlink
        stlink-gui
        stm32loader
        nodePackages.node-red
        gcc-arm-embedded
        octaveFull

        # POSIX utils capability
        om4
        pax
        mailutils
        sharutils
        flex
        bison
        universal-ctags
        inetutils
        uucp
        util-linux
        cflow
        ncompress

        # Nice programming language checkers and helpers
        gdb
        shellcheck
        valgrind
        cpplint
        cppcheck
        nixfmt-classic
        golint
        errcheck
        go-tools
        # eslint_d
        #flake8
        # html-tidy
        # Basic network utils for education and debugging
        socat
        httpie
        httpie-desktop
        netcat
        opcua-client-gui
      ];
  };

  fonts.packages = with pkgs; [
    jetbrains-mono
    inputs.gostfont.packages.x86_64-linux.gostfont
    corefonts
    liberation_ttf
  ];

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  programs.gnupg = {
    agent.enable = true;
    agent.enableSSHSupport = true;
  };
  programs.udevil.enable = true;
  services.devmon.enable = true;


  system.stateVersion = "24.05"; # Did you read the comment?

}

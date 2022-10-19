# This is my own NixOS config.
# NixOS - is GNU/Linux distribution with *declarative* system administration. 

# Mostly it's default, but also it contains several useful services.

{ config, pkgs, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
    ];
  
  # Save backup of current state of configuration.nix
  system.copySystemConfiguration = true;

  # Bootloader - standard EFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Enable networking
  networking = {
    hostName = "nixos";
    useDHCP = false;
    interfaces.wlp0s20f0u9.ipv4.addresses = [
      { address = "192.168.0.14";
        prefixLength = 24; } ];
  #  hosts = {
  #    "200:9063:7a61:fd91:3d08:cf96:59f1:4c48" = [ "gregorybednov.ygg" "gregorybednov.xmpp" ] ;
  #  };
  #  nameservers = [ "[200:9063:7a61:fd91:3d08:cf96:59f1:4c48]:53" ];
    networkmanager = {
      enable = true;
  #    dns = "none";
    };
  };

  # Enable network manager applet
  # programs.nm-applet.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  # Select internationalisation properties.
  #i18n.defaultLocale = "ru_RU.UTF-8"; 

  #i18n.extraLocaleSettings = {
  #  LC_ADDRESS = "ru_RU.utf8";
  #  LC_IDENTIFICATION = "ru_RU.utf8";
  #  LC_MEASUREMENT = "ru_RU.utf8";
  #  LC_MONETARY = "ru_RU.utf8";
  #  LC_NAME = "ru_RU.utf8";
  #  LC_NUMERIC = "ru_RU.utf8";
  #  LC_PAPER = "ru_RU.utf8";
  #  LC_TELEPHONE = "ru_RU.utf8";
  #  LC_TIME = "ru_RU.utf8";
  #};
  
  
  # Graphics & DE Enable - MATE is my favorite!
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.mate.enable = true;

  # Enable CUPS to print documents.
  # Still not configured for my own printer yet :/
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.users.bednovg = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "dav_group" "network" "wheel" ];
    cryptHomeLuks = "/dev/mapper/secret";
    packages = with pkgs; [
      firefox             # Browser (yes, it could be not chromium-based!)
      stellarium          # Astronomy simulator
      tdesktop            # Boring Telegram Desktop app. Unfortunately telegram-cli in NixOS 22.05 is outdated, and unstable edge is not for everyone
      pkgs.codeblocksFull # My first C/C++ IDE. Currently not using, but in love
      libreoffice         # For working with people don't recognize pure texts and csv
      jupyter             # For study at university      
    ];
  };
  
  # Allow unfree packages
  # nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim                 # The best text editor ever
    wget                # Nice downloader
  #  wine-staging       # Required for playing apps for not-so-nice platform :)
  #  pkgs.winetricks    # Also required with wine 
    curl                # Requests swiss-nife
    qbittorrent         # For sharing files
    elinks              # Nice text-based browser, the future of serfing :D
    pkgs.tectonic       # LaTeX engine
  #  pkgs.alfis         # Pretty blockchain-based DNS in Yggdrasil Network. Unfortunately has some issues 
    yggdrasil           # Autorounting mash-network works over Internet, radio and bluetooth. Gives you white IPv6
    rhvoice             # BEST OFFline Russian (and other Slavic language) TTS engine 
    radicale            # CalDAV and CardDAV server
    git                 # Do you know the difference between git and github? :P
    unzip               # ZIP unarchivier
    automake            # Make utilities
    mmake
    gnumake
    nginx               # Multipurpose webserver
  # pdnsd               # Caching DNS server
    gcc                 # GNU C Compiler
    tinycc              # really tiny C Compiler by genious programmer Fabrice Bellard
    pkgs.terminus_font  # Good-looking console font for cyrillic alphabets
    pkgs.aspellDicts.ru # Russian spellchecking dictionary
    pkgs.aspell         # Spellchecking app
  #  steam              # unfree game shop
  #  unrar              # unfree but popular archive format
  #  dosbox-staging     # for games and soft which is was not free but currently it doesn't matter
  
  openssl             # For selfsigning certificates
  # prosody             # XMPP server
  # psi                 # XMPP client
  # mpd                 # MPD server
  # ympd                # MPD client
  # mpc-cli             # MPD cli client
    mplayer         
    pkgs.cryptsetup    #
  ];
  
  #services.cron = {
  #  enable = true;
  #};
  
  console =  {
    earlySetup = true;
    font = "ter-v32n";
    packages = [ pkgs.terminus_font ];
    useXkbConfig = true;
  };

  #services.mpd = {
  #  user = "bednovg";
  #  enable = true;
  #  startWhenNeeded = true;
  #  network.listenAddress = "gregorybednov.ygg";
  #  extraConfig = ''
  #    audio_output {
  #      type "pipewire"
  #      name "My PipeWire Output"
  #    }
  #  '';
  #};
  #systemd.services.mpd.environment = { # mpd acts as system-user by default, here it is corrected to me to be visible for ympd player 
  #  XDG_RUNTIME_DIR = "/run/user/1000";
  #};
  
  #services.ympd = {
  #  enable = true;
  #  mpd.host = "gregorybednov.ygg";
  #  webPort = 51843;
  #};
  
  #services.prosody = {
  #  enable = true;
  #  admins = [ "root@gregorybednov.xmpp" ];
  #  ssl = {
  #    key  = "/root/prosody.key";
  #    cert = "/root/prosody.crt";
  #  };
  #  virtualHosts."gregorybednov.xmpp" = {
  #    enabled = true;
  #    domain = "gregorybednov.xmpp";
  #    ssl = {
  #      key  = "/root/prosody.key";
  #      cert = "/root/prosody.crt";
  #    };
  #  };
  #  muc = [ {
  #    domain = "conference.gregorybednov.xmpp";
  #  } ];
  #  uploadHttp = {
  #    domain = "upload.gregorybednov.xmpp";
  #  };
  #};

  #services.pdnsd = {
  #  enable = true;
  #  cacheDir = "/var/cache/pdnsd";
  #  globalConfig = "perm_cache=10240;min_ttl=60m;max_ttl=1w;neg_ttl=5m;par_queries=3;";
    #serverConfig = "ip=\"127.0.0.1\"; port=53; label='main'; ip = 217.10.44.35, 217.10.36.5, 217.10.32.4, 217.10.32.4;"; # forward to my local DNS provider
  #  serverConfig = "proxy_only=on; ip=\"200:9063:7a61:fd91:3d08:cf96:59f1:4c48\"; port=53; label='main'; ip = 217.10.44.35, 217.10.36.5, 217.10.32.4, 217.10.32.4;";
  #};
  #services.yggdrasil = {
  #  enable = true;
  #  persistentKeys = true;
  #  config = {
  #    Peers = [
  #      "tcp://94.130.203.208:5999"
  #      "tcp://92.124.136.131:30111"
  #      "tcp://188.225.9.167:18226"
  #      "tls://[2a01:d0:ffff:4353::2]:6010"
  #    ];
  #  };
  #};
  
  #services.nginx = {
  #  enable = true;
  #  recommendedTlsSettings = true;
  #  recommendedOptimisation = true;
  #  recommendedGzipSettings = true;
  #  virtualHosts."gregorybednov.ygg".root = "/srv/www";
  #};
 
  #services.radicale = {
  #  enable = true;
  #  settings = {
  #    server = {
  #      hosts = ["gregorybednov.ygg:5232"];
  #    };
  #    auth = {
  #      type = "htpasswd";
  #      htpasswd_filename = "/etc/radicale/users";
  #      htpasswd_encryption = "bcrypt";
  #    };
  #    storage = {
  #      filesystem_folder = "/var/lib/radicale/collections";
  #    };
  #  };
  #};

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    ports = [ 56666 ]; # It IS NOT my SSH port number but everyone know that 22 is in script-kiddies bombing forever 
    passwordAuthentication = false; # Only keys!!
    permitRootLogin = "no";
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ 80 443 5232  ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}

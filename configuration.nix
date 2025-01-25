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
  hasBootPartition = config.fileSystems ? "/boot";
  isNvidia = (builtins.readFile (pkgs.runCommandLocal "isNvidia" {} ''
	${pkgs.pciutils}/bin/lspci | ${pkgs.busybox}/bin/grep NVIDIA | ${pkgs.busybox}/bin/grep VGA > $out
  '')) != "";
in
{
  users.users.student = {
    isNormalUser = true;
    initialPassword = "student"; # вход беспарольный, но пароль student
    extraGroups = [ "video" "sound" "input" "storage" ];
    packages =
      let
        # определение как скачивать плагины jetbrains (скачивать с нашего сервера копию)
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

          # набор плагинов, я бы сказал, богат до избыточности, но главное есть Python
          # и Database Nagivator. Остальное - любителям и любознательным.
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
            # поддежка языка C/C++ на уровне подсветки синтаксиса и автодополнения
            (customJBPlugin "clsp" "1.0.1" "sha256-AU/Q61YYsGn2BAYykCGm4XGNyeSwd5K/txGNzP2dJg0=")

            # поддежка фреймворка Spring через opensource-плагин Explyt. пусть будет
            (customJBPlugin "spring-tool" "241-b3085-signed"
              "sha256-u9Hqy4BN1johA7e8proMekyERXkE6gXRnqGRNR7FouE="
            )
          ]
        ))

        chromium # браузер
        pinta    # графический редактор
        sakura   # терминал
        unzipNLS # поддержка zip
        unrar    # поддержка rar
        gtk3 whitesur-icon-theme # необходимо для иконок
        (pkgs.writeShellScriptBin "powermenu" (builtins.readFile inputs.mireadesktop.packages.x86_64-linux.powermenu))
        (pkgs.writeShellScriptBin "resethome" (builtins.readFile inputs.mireadesktop.packages.x86_64-linux.startmireadesktop))

        pandoc
        #onlyoffice-desktopeditors # к сожалению, пока у OnlyOffice баг со шрифтами. Ждём фикс
        libreoffice # поэтому пока что у нас Libreoffice...

        # Напоминаю что у нас есть СЕТЕВОЙ ДИСК по адресу 10.0.174.12
        # и для студентов пока есть единая учётка student@mirea.ru,
        # рассматривается вариант авторизации через login.mirea.ru.
        # Преподаватели могут зарегистрироваться ОТДЕЛЬНО
        seafile-client

        # утилиты разработчика
        git
        cmakeWithGui
        gnumake

        ######    ЯЗЫКИ ПРОГРАММИРОВАНИЯ    #####

        # поставка Python, полный список возможностей
        # см. на github.com/gregorybednov/mireapython
        inputs.mireapython.packages.x86_64-linux.mireapython 

        # базовая поддержка C/C++ и дебага
        clang
        clang-tools
        lldb
        cpplint
        cppcheck
        gcc-arm-embedded # компиляция С/C++ под STM32 и прочие arm
        
        octaveFull # GNU Octave

        shellcheck # проверка шелл-кода (bash, POSIX sh, ...)

        # Другие возможные языки и инструменты, например:
        # rustc                               # - Rust
        # go gopls delve golint go-tools      # - Go
        jdk kotlin                            # - Java, Kotlin (идут вместе с IJ IDEA)
        # ghc haskell-language-server         # - Haskell
        # nodePackages.intelephense           # - PHP      
        # dotnet-sdk                          # - C#

        ####### Проектирование и разработка баз данных, ИУС, ... #######

        # Workbench для управления и ER-моделирования БД на mysql
        # у КАЖДОГО nixos есть свой локальный сервер mysql, см. ниже по файлу
        mysql-workbench
        
        # аналог Bizagi Modeler, расширенный вариант bpmn.io
        camunda-modeler

        # графическое моделирование UML-диаграмм
        # также доступно моделирование BPMN и ER 
        staruml

        # Язык текстового описания UML-диаграмм
        # актуально для разработчиков ПО (встраивание диаграмм в код)
        # поддерживается нашей поставкой IJ IDEA CE
        plantuml
        
        archi # поддержка archimate


        ##### Утилиты и программы для STM32 #####
        # 1) STM32CubeIDE упаковать не удалось
        # 2) есть основания полагать, что её функциональность лучше встроить
        #    в IJ IDEA CE, как это сделано в настоящем Clion;
        stm32cubemx.packages.x86_64-linux.stm32cubemx
        stm32flash
        stlink
        stlink-gui
        stm32loader

        ##### СЕТЕВЫЕ УТИЛИТЫ #######
        nodePackages.node-red # - лоукод-платформа программирования устройств, в частности интернета вещей
        httpie httpie-desktop # - передовой клиент HTTP-запросов
        netcat socat          # - низкоуровневые простейшие утилиты установления TCP или UDP между компьютерами или с ПЛК
        opcua-client-gui      # - простой графический клиент OPC UA

        ###### Другой софт #######

        logisim-evolution
        unityhub # UnityHub - 3D-моделирование, визуализация, геймдев, AR/VR

        # поставка SimInTech. Кодогенерация библиотек для ПК работает,
        # но несовместима с .dll из windows!
        simintech.packages.x86_64-linux.simintech
        
        # POSIX утилиты для совместимости
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
      ];
  };

  # вставленные флешки автоматически монтируются
  services.devmon.enable = true; 

  # необходимо для совместимости с POSIX по команде at, при отсутствии необходимости можно удалить
  services.atd = { 
    enable = true;
    allowEveryone = true;
  };

  # на каждой машине свой сервер mysql и postgresql
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
  
  # и оба поддерживают вход без пароля в "руты"
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

  imports = [ ./hardware-configuration.nix ];

  # если машина установлена на диск с Windows,
  # то она позволяет "увидеть" и выбрать Windows в течение 30 с
  # иначе - 5 c таймаута (для виртуалок)
  boot.loader = if hasBootPartition then {
    efi.canTouchEfiVariables = true;
    timeout = 30;
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
      theme = "${pkgs.sleek-grub-theme.override{ withStyle = "orange"; withBanner = "Выберите ОС"; }}";
    };
  } else {
    timeout = 5;
    grub = {
      enable = true;
      device = "/dev/sda";
      theme = "${pkgs.sleek-grub-theme.override{ withStyle = "orange"; withBanner = "Загрузчик Linux"; }}";
    };
  };
  time.hardwareClockInLocalTime = hasBootPartition;

  # настройки Nix
  nixpkgs.config.allowUnfree = true;
  nix.settings.auto-optimise-store = true;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  ##### НАСТРОЙКИ ГРАФИКИ И РАБОЧЕГО СТОЛА ######
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.xserver = {
    enable = true;
    xkb.layout = "us,ru";
    xkb.options = "grp:alt_shift_toggle";
  };
  services.displayManager.autoLogin.user = "student";
  services.getty.autologinUser = "student";
  services.xserver.displayManager.lightdm.enable = true;
  services.displayManager.defaultSession = "MIREA-WindowsLike+Metacity";
  services.xserver.displayManager.session = [
    {
      manage = "desktop";
      name = "MIREA-WindowsLike";
      # подробности настроек рабочего стола см. на github.com/gregorybednov/mireadesktop
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

  ##### СЕТЕВЫЕ НАСТРОЙКИ #######
  # каждый компьютер виден под уникальным именем через Avahi
  services.avahi = {
    hostName = "nixos" 
      + builtins.readFile ((pkgs.runCommandLocal "uuid" {} ''
	      mkdir $out
	      cat /proc/sys/kernel/random/uuid > $out/uuid
        '')+"/uuid");
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      hinfo = true;
      addresses = true;
    };
  };

  # каждый компьютер имеет выход в интернет
  networking.networkmanager.enable = true;

  networking.hostName = "nixos";
  
  # каждый компьютер ресолвит DNS-запросы СТРОГО через наш сервер
  networking.nameservers = [ serverIP ];
  
  # каждый компьютер знает, что kafpi.local - это адрес нашего сервера
  networking.hosts."${serverIP}" = [ "kafpi.local" ];
  
  #### ЛОКАЛИЗАЦИЯ #####

  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "ru_RU.UTF-8";
  console = {
    font = "cyr-sun16";
    useXkbConfig = true;
  };

  # установлены шрифты Microsoft (corefonts),
  # установлен ГОСТ Тип А (задел на будущее),
  # установлены базовые свободные шрифты,
  # установлен шрифт Jetbrains Mono
  fonts.packages = with pkgs; [
    jetbrains-mono
    inputs.gostfont.packages.x86_64-linux.gostfont
    corefonts
    liberation_ttf
  ];


  ####### ПРОЧИЕ НАСТРОЙКИ #######
  environment.systemPackages = with pkgs; [
    vim
    tree
    wget
    git
  ];

  # удаленный доступ в пределах нашей сети
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  services.gnome.gnome-keyring.enable = true;

  programs = {
    java.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    chromium = {
      enable = true;
      extraOpts = {
        "SyncDisabled" = true;
        "PasswordManagerEnabled" = false;
        "SpellcheckEnabled" = false;
        "homepageLocation" = "https://ya.ru";
      };
    };
    udevil.enable = true; # тоже нужно для флешек
  };

  # НЕ МЕНЯТЬ, иначе придётся все компы переустанавливать, а не обновлять
  system.stateVersion = "24.05";
}

# Modifications par rapport à l'ISO officielle CachyOS

Ce dépôt est dérivé de [cachyos-live-iso](https://github.com/cachyos/cachyos-live-iso).
L'ISO officielle démarre sur KDE Plasma ; celle-ci démarre sur **XFCE, en français**,
avec un sélecteur de thèmes, et son installeur installe, **en ligne et à jour**,
au choix **ce même bureau XFCE** ou **le bureau Openbox de Packarch**.

## Sommaire

1. [Reconstruire l'ISO](#1-reconstruire-liso)
2. [Bureau : KDE Plasma remplacé par XFCE](#2-bureau--kde-plasma-remplacé-par-xfce)
3. [Langue, clavier et fuseau horaire](#3-langue-clavier-et-fuseau-horaire)
4. [Réglages XFCE du live](#4-réglages-xfce-du-live)
5. [Sélecteur de thèmes](#5-sélecteur-de-thèmes)
6. [Installeur Calamares](#6-installeur-calamares)
7. [Liste des fichiers modifiés ou ajoutés](#7-liste-des-fichiers-modifiés-ou-ajoutés)
8. [Points connus](#8-points-connus)

---

## 1. Reconstruire l'ISO

### Prérequis (une seule fois)

Sur un système CachyOS ou Arch Linux, avec les dépôts CachyOS configurés :

```bash
sudo pacman -S --needed archiso mkinitcpio-archiso squashfs-tools grub git base-devel
```

Les dépendances de compilation de Calamares (Qt 6, bibliothèques KDE, boost,
cmake…) sont installées automatiquement par `makepkg --syncdeps` à la première
compilation (mot de passe `sudo` demandé). Pour les installer à l'avance, comme
dépendances, afin de pouvoir les retirer facilement ensuite :

```bash
cd calamares
bash -c 'source PKGBUILD; sudo pacman -S --needed --asdeps "${depends[@]}" "${makedepends[@]}"'
```

Pour les retirer plus tard : `sudo pacman -Rns $(pacman -Qdtq)`.

### Construction

Depuis la racine du dépôt, **en utilisateur normal** (le mot de passe `sudo`
est demandé pour l'étape 2) :

```bash
./build.sh          # ou ./build.sh -v pour un journal détaillé
```

`build.sh` enchaîne :

1. `calamares/build.sh` : compile notre Calamares et le met dans le dépôt
   local `localrepo/`
   (`makepkg` refuse de tourner en root), **sauf si cette version y est
   déjà** : monter `pkgrel` après chaque modification du patch, ou forcer
   avec `-f` ;
2. `sudo scripts/buildiso.sh -p desktop -w` : construit l'ISO puis supprime le
   dossier de travail `build/` ;
4. rend à l'utilisateur les fichiers de `out/` (produits par root).

- L'ISO est produite dans `out/desktop/` :
  `cachyos-desktop-linux-AAMMJJ.iso`, avec ses sommes `.sha256`/`.sha1` et la
  liste des paquets `.pkgs.txt`.
- Options de `build.sh` : `-f` recompiler Calamares même si sa version est
  déjà dans `localrepo/` ; transmises à `buildiso.sh` : `-v` journal détaillé,
  `-c` ne pas vider le dossier de travail avant, `-r` construire en RAM (plus
  de 23 Go de RAM).
- `scripts/` contient la machinerie d'origine de CachyOS (`buildiso.sh`,
  `util.sh`, `util-msg.sh`, `util-iso.sh`, `util-iso-mount.sh`), qu'il n'est
  plus nécessaire d'appeler directement.

### Tester dans une VM (QEMU/KVM, UEFI)

```bash
sudo pacman -S --needed qemu-desktop edk2-ovmf

./run.sh                   # live (ISO la plus récente de out/)
./run.sh -i                # système installé (--installe)
./run.sh --iso FICHIER     # live d'une ISO précise
```

`run.sh` garde dans `vm-test/` le disque virtuel `disque.qcow2` (30 Go, créé
s'il manque) et les variables UEFI `OVMF_VARS.fd`. Le live démarre toujours en
premier (`bootindex`), même quand GRUB du système installé est enregistré dans
les variables UEFI. L'affichage utilise `virtio-vga` **sans accélération 3D**
(avec `virtio-vga-gl` et une carte NVIDIA, la fenêtre reste noire), en
1600×900 au démarrage, l'image étant adaptée à la taille de la fenêtre ; dans
le live, le bouton « Ajuster la résolution » applique la taille de la fenêtre.

### Nettoyer le projet

```bash
./reset.sh        # demande confirmation ; -y sans confirmation
./reset.sh -k     # garde la machine virtuelle (vm-test/)
```

Supprime tout ce que `build.sh` et `run.sh` génèrent : `out/`, `build/`,
`localrepo/`, la compilation de Calamares (`calamares/src`, `pkg`,
`calamares`, `*.pkg.tar.zst`), les fichiers écrits dans
`archiso/` par `scripts/util-iso.sh` (voir section 7) et `vm-test/`, et
remet la date de l'ISO, que `util-iso.sh` écrit dans `archiso/grub/grub.cfg`
à chaque build, à `CACHYOS_VERSION="AAMMJJ"` ; `.gitignore` exclut de toute
façon les mêmes chemins (sauf `grub.cfg`, fichier source).

Supprimés de l'original : `testiso.sh` (VirtualBox), `ci.build.sh` (appelait
un `fix_permissions.sh` absent), `lddd.sh` (outil de développement CachyOS,
inutilisé), `machines/` et `testcases/` (tests automatiques openQA/quickemu
de CachyOS, inutilisés).

---

## 2. Bureau : KDE Plasma remplacé par XFCE

Liste : `archiso/packages_desktop.x86_64`.

**Retirés :**
`plasma-desktop`, `plasma-workspace`, `plasma-integration`, `plasma-nm`,
`plasma-pa`, `plasma-thunderbolt`, `plasma-login-manager`, `polkit-kde-agent`,
`cachyos-kde-settings`, `kxkb2locale1`, `bluedevil`, `breeze-gtk`,
`kde-gtk-config`, `kinfocenter`, `kscreen`, `dolphin`, `konsole`, `kate`,
`kcalc`, `spectacle`, `partitionmanager` (gparted reste),
`alacritty`, `micro`, `vim`, `lftp`,
le noyau LTS (`linux-cachyos-lts`, `linux-cachyos-lts-nvidia-open`,
`linux-cachyos-lts-zfs`) et les outils de secours `clonezilla`, `partimage`,
`irssi`, `lynx`, `wvdial`, `xl2tpd`.

**Un seul noyau : `linux-cachyos`.** Le live démarre dessus partout (GRUB,
syslinux, systemd-boot, `grub/loopback.cfg`) : entrée « CachyOS LTS Kernel »
de GRUB retirée, entrée systemd-boot `02-archiso-linux-cachyos.conf` retirée
(doublon de `01-archiso-linux.conf`), et
`airootfs/etc/mkinitcpio.d/linux.preset` (initramfs du live) pointe sur
`linux-cachyos`. Le système installé n'a pas de LTS non plus (voir
[Autres corrections dans `live-offline.patch`](#autres-corrections-dans-live-offlinepatch)).

**Ajoutés :**

| Rôle | Paquets |
|---|---|
| Bureau | `xfce4`, les extensions de `xfce4-goodies` **sauf** `parole`, `xfburn`, `xfce4-sensors-plugin` et `mousepad`, `thunar-archive-plugin`, `thunar-media-tags-plugin`, `cachyos-xfce-settings` (thème CachyOS pour XFCE, base de notre `/etc/skel` ; **live seulement** : le système installé reçoit le `/etc/skel` du live, et `qogir-icon-theme` à sa place) |
| Affichage et connexion | `xorg-server`, `xf86-input-libinput`, `lightdm`, `lightdm-gtk-greeter`, `lightdm-gtk-greeter-settings` |
| Remplaçants des outils KDE | `network-manager-applet`, `blueman`, `pavucontrol`, `polkit-gnome`, `gvfs`, `gvfs-mtp`, `gvfs-smb`, `file-roller`, `xarchiver`, `ristretto`, `catfish` (recherche de fichiers) |
| Applications | `geany` (seul éditeur graphique, avec `nano` en console), `meld` (comparaison de fichiers), `smplayer`, `smplayer-skins`, `smplayer-themes` (et `mpv` en dépendance), `btop`, `yay` |
| Applications de l'auteur (dépôt Packarch) | `cryptyrust` (chiffrement de fichiers), `liloucalc` (calculatrice scientifique), `nounours-player` (lecteur multimédia), `packarch-rmatrix` (effet « Matrix » en console) |
| Démarrage | `cachyos-grub-theme` |

`vim` n'est plus installé : `cachyos-zsh-config`, qui l'exigeait sans s'en
servir, est remplacé par `packarch-zsh-config` (voir ci-dessous).

`cachyos-xfce-settings` n'est pas installé sur le système installé : ses
fichiers de `/etc/skel` y sont déjà (modifiés) par la copie du `/etc/skel` du
live, et ses mises à jour les remplaceraient par ceux de CachyOS. De ses
dépendances, seul `qogir-icon-theme` (curseur Qogir-Dark) est utile et pas déjà
dans `netinstall_live.conf` : il y est ajouté (groupe commun aux deux
bureaux). kvantum, qt5ct, les thèmes Nord et `char-white`, `capitaine-cursors`,
`cachyos-alacritty-config`, `ttf-fantasque-nerd` et `ttf-fira-sans` ne sont
plus installés (inutilisés par notre configuration).

**Shell par défaut : zsh** avec la configuration de `cachyos-zsh-config` (oh-my-zsh,
powerlevel10k, autosuggestions, coloration syntaxique), sur le live comme sur le
système installé. Elle est installée par `packarch-zsh-config` ([packarch]) :
mêmes fichiers, renommés (`/etc/skel/.zshrc`,
`/usr/share/packarch-zsh-config/packarch-config.zsh` au lieu de
`/usr/share/cachyos-zsh-config/cachyos-config.zsh`, depuis 1.0.3-3) et mêmes
dépendances, sauf `vim`, dont elle ne se sert pas ; il fournit
`cachyos-zsh-config`, exigé par `cachyos-xfce-settings` sur le live :

- live : `packarch-zsh-config` ajouté à `packages_desktop.x86_64` (son
  `/etc/skel/.zshrc` est copié dans `/home/liveuser` par mkarchiso),
  `etc/passwd` donne `/usr/bin/zsh` à `root` et `liveuser`, et
  `root/.zshrc` charge la même configuration pour root ;
- système installé : `users.conf` (dans `live-offline.patch`) crée l'utilisateur
  avec `/bin/zsh` ; `packarch-zsh-config` est dans `netinstall_live.conf`
  et son `.zshrc` passe par `/etc/skel`. Root garde bash en installation en
  ligne. Le script `shell-setup` de Calamares, lancé à la fin, essaie zsh
  avant fish (l'original choisissait fish dès qu'il était installé) ;
- `cachyos-fish-config` (et donc fish) retiré du live et de
  `netinstall_live.conf` : inutile avec zsh.

Toute la configuration zsh est dans `packarch-zsh-config`, rien n'est modifié
après son installation :
- **powerlevel10k par défaut** : `/usr/share/packarch-zsh-config/p10k.zsh`,
  style *lean* sur une ligne en mode `ascii` (aucune police Nerd nécessaire,
  lisible aussi en console), chargé quand `~/.p10k.zsh` n'existe pas : pas
  d'assistant `p10k configure` au premier démarrage, ni de `.p10k.zsh` à
  copier dans `/etc/skel` ou `/root`. `p10k configure` écrit `~/.p10k.zsh`,
  qui prend alors le dessus. Pour changer le style par défaut : modifier
  `p10k.zsh` dans le paquet ;
- **alias `cleanup`** entre apostrophes : la liste des paquets orphelins
  (`pacman -Qtdq`) est calculée quand on l'utilise, et plus à chaque
  démarrage de zsh. Sur le live, sans bases de synchronisation (supprimées par
  mkarchiso), cet appel affichait « database file for '…' does not exist » et
  l'alerte *instant prompt* de powerlevel10k dans chaque terminal ; le
  contournement `etc/zsh/zshrc` du live n'est plus nécessaire ;
- dépendance `expac`, utilisée par l'alias `rip`.

**Gestionnaire de connexion** : `scripts/util-iso.sh` active `lightdm.service` au lieu
de `plasmalogin.service`. Connexion automatique de `liveuser` en session XFCE
par `etc/lightdm/lightdm.conf.d/50-cachyos-live.conf` (supprimé du système
installé par `removeun` et `removeun-online`).

**Supprimés de `airootfs`** (réglages KDE) : `etc/plasmalogin.conf`,
`etc/plasmalogin.conf.d/`, le hook `90-cachyos-live-kwin-keyboard.hook`, et dans
`etc/skel/.config/` : `kded5rc`, `kscreenlockerrc`, `kwalletrc`,
`plasma-welcomerc`, `powerdevilrc`, `powermanagementprofilesrc`,
`systemd/user/plasma-login-kwin_wayland.service.d/`.

---

## 3. Langue, clavier et fuseau horaire

| Fichier (`archiso/airootfs/`) | Valeur |
|---|---|
| `etc/locale.conf` | `LANG=fr_FR.UTF-8` (avant : `C.UTF-8`) |
| `etc/locale.gen` | `fr_FR.UTF-8` et `en_US.UTF-8` |
| `etc/pacman.d/hooks/40-cachyos-live-locale-gen.hook` | lance `locale-gen` pendant le build |
| `etc/pacman.d/hooks/90-geany-new-instance.hook` | `geany.desktop` lance `geany -i %F` : une nouvelle instance à chaque ouverture ; gardé sur le live et copié sur le système installé par `apply-live-config` (réappliqué à chaque mise à jour de `geany`) |
| `etc/pacman.d/hooks/90-hide-desktop-entries.hook` + `usr/local/bin/hide-desktop-entries` | ajoute `NoDisplay=true` (entrée cachée des menus XFCE et rofi, mais toujours utilisable comme application par défaut) à « À propos de Xfce » (`xfce4-about`), « Émulateur de terminal », « Lecteur de courriels », « Navigateur web » (`xfce4-terminal-emulator`, `xfce4-mail-reader`, `xfce4-web-browser`), Plank, mpv, Qt V4L2 test/video (`qv4l2`, `qvidcap`), Rofi et Rofi Theme Selector ; gardé sur le live et copié sur le système installé (XFCE et Openbox) par `apply-live-config`, qui l'applique aussi tout de suite (réappliqué à chaque mise à jour des paquets concernés) |
| `etc/vconsole.conf` | `KEYMAP=fr-latin9` (consoles texte) |
| `etc/X11/xorg.conf.d/00-keyboard.conf` | `XkbLayout fr` (LightDM et XFCE) |
| `etc/localtime` | lien vers `Europe/Paris` (avant : `UTC`) |

---

## 4. Réglages XFCE du live

### Pourquoi un hook pacman

`mkarchiso` copie `airootfs` **avant** d'installer les paquets : un fichier de
`airootfs` qui existe aussi dans un paquet fait échouer le build. Or
`cachyos-xfce-settings` fournit déjà ses réglages dans `/etc/skel`. Ils sont donc
modifiés **après** l'installation des paquets par
`etc/pacman.d/hooks/80-cachyos-live-xfce-skel.hook`, qui lance
`80-cachyos-live-xfce-skel.sh` (même méthode que l'ancien hook KWin). Les deux
fichiers contiennent `remove from airootfs!` : le hook d'origine
`zzzz99-remove-custom-hooks-from-airootfs.hook` les retire de l'ISO à la fin.

### Ce que fait le hook

- **Pas de verrouillage ni de mise en veille** : `xfce4-power-manager.xml`
  (écran jamais éteint, ordinateur jamais mis en veille, pas de verrouillage à
  la veille), `xfce4-screensaver.xml` (économiseur et verrouillage désactivés),
  `xfce4-session.xml` (pas de verrouillage à l'extinction). Équivalent des
  anciens fichiers KDE. S'y ajoute `etc/X11/xorg.conf.d/10-no-blanking.conf`
  (dans `airootfs`, copié sur le système installé par `apply-live-config`) :
  le serveur X n'éteint plus l'écran de lui-même après 10 minutes, y compris
  sur l'écran de connexion LightDM. De même,
  `etc/lightdm/lightdm.conf.d/40-numlock.conf` (`greeter-setup-script=/usr/bin/numlockx on`,
  paquet `numlockx` sur le live et dans `netinstall_live.conf`) allume le pavé
  numérique dès l'écran de connexion.
- **Actions personnalisées de Thunar** (`uca.xml`), `sudo` étant sans mot de
  passe pour le groupe `wheel` :
  - « Thunar Root » : `sudo thunar %f` (au lieu de `pkexec`), icône
    `folder-red` ;
  - « Open a root terminal here » devient « Terminal root » :
    `sudo xfce4-terminal --default-working-directory=%f` (au lieu de `pkexec`) ;
  - « Set as desktop background » supprimée : le greffon de fond d'écran de
    Thunar propose déjà « Définir comme fond d'écran » (et la commande de
    l'action écrivait dans `/backdrop/screen0/monitor0/image-path`, que
    xfdesktop 4.20 ne lit plus).
- **Thunar** (`thunar.xml`) : barre de menus cachée (Ctrl+M l'affiche) et
  entrée « Supprimer » (sans passer par la corbeille) dans le menu contextuel.
  Même réglage dans le `thunar.xml` de `packarch-openbox`.
- **Geany comme éditeur** : `mimeapps.list` remplace `mousepad.desktop` par
  `geany.desktop`.
- **Firefox au lieu de Cachy Browser** (absent de l'ISO) : bouton du tableau de
  bord (`launcher-20`), navigateur par défaut (`helpers.rc`), favoris du menu
  Whisker (Parole et epdfview retirés des favoris).
- **Icône du bouton Thunar** : `default-folder` (absente de la plupart des
  thèmes d'icônes) remplacée par `org.xfce.thunar`.
- **Bouton du sélecteur de thèmes** : lanceur `plugin-30` ajouté après le
  moniteur système, avec « default » en première entrée.
- **Bouton « Ajuster la résolution » (live seulement)** : lanceur `plugin-31`
  (`launcher-31/live-fit-display.desktop`, dans `airootfs/etc/skel`) après le
  sélecteur de thèmes. Il lance `/usr/local/bin/live-fit-display`
  (`xrandr --output <écran> --auto`) : dans une machine virtuelle, applique la
  taille de la fenêtre, que XFCE n'applique pas tout seul. `apply-live-config`
  le retire du `/etc/skel` du système installé, où le script n'existe pas.
- **Thème « default » dès le démarrage** : `xsettings.xml` (thème GTK
  `Arc-Dark`, icônes `Luna-Purple-Dark`, curseur `Qogir-Dark` au lieu de
  `capitaine-cursors`), `xfwm4.xml` (bordures `Arc-Dark`),
  `xfce4-desktop.xml` (fond `default.png`), couleurs du terminal ajoutées à
  `terminalrc` (xfce4-terminal les importe dans xfconf au premier lancement).
- **Curseur `Qogir-Dark`** (fourni par `qogir-icon-theme`) : le sélecteur de
  thèmes ne le change pas.
- **Greeter LightDM sombre** (système installé, XFCE et Openbox) :
  `apply-live-config` règle dans `/etc/lightdm/lightdm-gtk-greeter.conf` le
  thème GTK `Greybird-dark` (`packarch-themes`), les icônes `Luna-Red-Dark`
  (`packarch-icons`) et le curseur `Qogir-Dark` (`qogir-icon-theme`).
- **Pas de galculator** : retiré de l'ISO et de l'installation en ligne ; le
  favori du menu Whisker et la touche Calculatrice (`XF86Calculator` dans
  `xfce4-keyboard-shortcuts.xml`) lancent LilouCalc à la place.
- **Pavé numérique activé** : `keyboards.xml`, `Numlock` à `true`.

### Fichiers ajoutés directement dans `etc/skel`

(aucun paquet ne les fournit, donc pas de conflit)

- `.config/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml` : pas de montage
  ni d'ouverture automatiques des disques.
- `.config/xfce4/panel/launcher-30/theme-*.desktop` : les 7 entrées du bouton de
  thèmes.
- `.config/smplayer/smplayer.ini` : interface personnalisée (`gui=SkinGUI`),
  thème `Black`, style Qt `Fusion`, lecteur `mpv`.
- `.config/geany/geany.conf` : réglages de Geany (police JetBrainsMono Nerd
  Font, thème `darcula`, barre d'outils masquée...), copiés d'une configuration
  personnelle, nom et adresse des modèles (`pref_template_*`) vidés, terminal
  `xfce4-terminal` au lieu de `xterm`. La police vient de
  `ttf-jetbrains-mono-nerd`, ajouté à l'ISO et à l'installation.
- `.config/xfcethemes/` : `.current_theme` (`default`) et des liens vers le
  script et les icônes de `/usr/share/xfcethemes`.
- `.xprofile` : lance `init-backdrop.sh` (voir ci-dessous).

---

## 5. Sélecteur de thèmes

Repris de `~/.config/xfcethemes/` de l'auteur et installé pour tous les
utilisateurs dans `archiso/airootfs/usr/share/xfcethemes/` :

- `theme-switcher.sh --<thème>` (`blue`, `gray`, `green`, `purple`, `red`,
  `yellow`, `default`) : applique fond d'écran aléatoire du thème, thème GTK,
  bordures, icônes et couleurs du terminal. Différences avec l'original :
  - l'état (`.current_theme`, `.last_wallpaper/`) est enregistré dans
    `~/.config/xfcethemes/`, `/usr/share` n'étant pas modifiable ;
  - le fond d'écran est aussi écrit dans les réglages par nom d'écran de
    xfdesktop 4.20 (`/backdrop/screen0/monitor<SORTIE>/workspace<N>/last-image`),
    absents d'une session neuve ;
  - le thème appliqué est placé en tête du lanceur du tableau de bord, qui
    affiche ainsi le thème actif, y compris après redémarrage (cette dernière
    modification a aussi été faite sur la machine de l'auteur) ;
  - thème GTK du thème jaune : `Juno-Mirage` (nom actuel du thème, fourni par
    `packarch-themes`).
- `init-backdrop.sh` : lancé par `~/.xprofile` avant l'ouverture de la session
  (LightDM). Crée le réglage du fond d'écran des écrans branchés s'il manque.
  Sans lui, xfdesktop 4.20 affiche la souris XFCE : la configuration CachyOS
  utilise l'ancien format `monitor0`, que xfdesktop supprime en le convertissant.
- `icons/<thème>.png`. Les fonds d'écran sont dans le paquet
  `packarch-backgrounds`, tous directement dans `/usr/share/backgrounds`
  (depuis 2.0-3 : plus de sous-dossier `xfcethemes/<thème>/` ni de liens
  symboliques, que nitrogen affichait en double sous Openbox) ;
  `theme-switcher.sh` contient la liste des fichiers de chaque thème
  (`WALLPAPERS`), le thème « default » utilise `xfce-default.png`.

**Thèmes du dépôt Packarch** ([myrepo](https://github.com/Antidote1911/myrepo)
de l'auteur) :

- dépôt `[packarch]` (`SigLevel = Optional TrustAll`,
  `Include = /etc/pacman.d/packarch-mirrorlist`) ajouté à la fin de
  `etc/pacman.conf` (live) et de `etc/pacman-more.conf` (copié comme
  `pacman.conf` du système installé). Pour le build, `archiso/pacman.conf`
  le déclare avec `Server = https://antidote1911.github.io/myrepo/$arch`
  (pas besoin du fichier de miroirs sur la machine qui construit l'ISO).
- `etc/pacman.d/packarch-mirrorlist` est fourni par `airootfs` et **non** par le
  paquet `packarch-mirrorlist` : ce paquet ne le déclare pas en `backup`, et Calamares
  doit le copier sur le système installé **avant** pacstrap (voir section 6),
  ce qui ferait échouer l'installation du paquet (« existe déjà »).
- paquets installés (live et système installé), un par catégorie, chacun
  complet (sources : [myrepo-pkgs](https://github.com/Antidote1911/myrepo-pkgs)) :
  `packarch-themes` (tous les thèmes GTK et Openbox : `Arc-Dark`,
  `Juno-Mirage`, `Dracula`, `Gruvbox`, `Nordic`, `Greybird-dark`,
  `Orchis-Red-Dark`…), `packarch-icons` (toutes les icônes : `Luna-*`,
  `Packarch(-Dark)`, `Vimix-Black(-Dark)`, `Papirus-Apps`… ; dépend de
  `qogir-icon-theme` et `papirus-icon-theme`), `packarch-backgrounds` (tous
  les fonds d'écran). Les icônes se complètent par héritage : `Luna-*-Dark` →
  `Packarch-Dark` → `Papirus-Apps`, `Papirus-Dark`.
- plus aucun thème, icône ni fond d'écran n'est copié à la main dans
  `airootfs` (ni copié par `apply-live-config`).

---

## 6. Installeur Calamares

### Pourquoi recompiler Calamares

1. Le paquet officiel `cachyos-calamares-next` 3.4.2-13 était lié à
   `libboost_python314.so.1.91.0` alors que les dépôts fournissent boost 1.92 :
   Calamares ne démarrait pas.
2. Ses fichiers de configuration (`/etc/calamares/…`) appartiennent au paquet et
   ne peuvent pas être remplacés depuis `airootfs`.

Le dossier `calamares/` contient donc :

| Fichier | Rôle |
|---|---|
| `PKGBUILD` | celui de [CachyOS-PKGBUILDS](https://github.com/CachyOS/CachyOS-PKGBUILDS) (`cachyos-calamares/`), version `3.4.2-13.8`, figé sur le commit `199d71543db8` de la branche `cachyos-dev`, applique `live-offline.patch` |
| `live-offline.patch` | nos modifications des sources (détail ci-dessous) |
| `build.sh` | `makepkg`, puis copie du paquet dans `localrepo/` et `repo-add` ; rien si cette version y est déjà (`-f` : recompiler quand même) |

Calamares est compilé avec
`scripts/makepkg-generic.conf` (`makepkg --config`) : la configuration du
système, mais en code x86-64 générique (`-march=x86-64 -mtune=generic -O2`).
Le `makepkg.conf` de CachyOS peut utiliser `-march=native`, et ces programmes
tournent sur le live ou le système installé, sur n'importe quel processeur.

`scripts/util-iso.sh` ajoute le dépôt local `[cachyos-live-local]`
(`Server = file://…/localrepo`, `SigLevel = Optional TrustAll`) **avant**
`[cachyos]` dans la copie de `pacman.conf` utilisée par le build : l'ISO prend
notre Calamares plutôt que l'officiel.

### Installation en ligne (mode par défaut)

`settings_online.conf` reste la base (installation officielle de CachyOS :
`pacstrap`, choix du chargeur de démarrage, etc.) avec ces changements :

- **Page « Bureau »** (`packagechooser@desktop`, avant « Paquets ») réduite à
  deux choix : **XFCE** (par défaut, le bureau du live) ou **Openbox** (celui
  de Packarch, voir [Bureau Openbox](#bureau-openbox-packarch)). Le live, lui,
  démarre toujours sur XFCE.
- **`shellprocess@initialize_pacman`** copie aussi
  `/etc/pacman.d/packarch-mirrorlist` sur le système installé, avec les
  listes de miroirs CachyOS : pacstrap et pacman y lisent le `pacman.conf` du
  système installé, qui inclut `[packarch]`.
- **`netinstall@live`** (`netinstall_live.conf`) remplace la liste de paquets
  de CachyOS :
  - groupes cachés et obligatoires : base CachyOS (noyau `linux-cachyos`
    seul, microcode, outils CachyOS, réseau, pare-feu, bluetooth,
    son, polices, matériel…, **sans `alacritty` ni `micro`**) et **les
    applications du live communes aux deux bureaux** (LightDM, Xorg, geany,
    smplayer, firefox et `firefox-i18n-fr`, applications Packarch…) ;
  - deux groupes cachés **`XFCE`** et **`Openbox`**, décochés : la page
    « Bureau » coche celui dont le nom est l'identifiant du choix (méthode
    `netinstall-select`). `XFCE` contient le bureau du live (mêmes paquets que
    l'ISO, dont les thèmes du sélecteur) ; `Openbox` contient
    `packarch-openbox`, les greffons Thunar et les thèmes GTK/icônes Packarch
    des thèmes Openbox. Calamares ne savait pas cocher un groupe **caché**
    par son nom (ces groupes ne sont pas dans l'arbre parcouru) :
    `netinstall/PackageModel.cpp` les parcourt aussi (3 lignes) ;
  - **cases à cocher** (décochées par défaut), rangées par catégorie
    (sous-groupes `subgroups`, dépliés) :

    | Catégorie | Logiciels |
    |---|---|
    | Internet | Discord, FileZilla |
    | Bureautique | LibreOffice (`libreoffice-fresh` + `libreoffice-fresh-fr`) |
    | Graphisme | GIMP |
    | Jeux | Steam, Bombicat (`[packarch]`) |
    | Développement | Rust (`rustup`), Qt Creator |
    | Utilitaires | KeePassXC, Deadpool (`[packarch]`) |
    | Système | Impression (CUPS), Accessibilité |
- **`shellprocess@live_config`**, après l'installation des paquets : lance
  `/usr/local/bin/apply-live-config` (fourni par l'ISO). Il reconnaît le bureau
  choisi aux paquets installés (`openbox` sans `xfce4-session` : Openbox).
  **XFCE** : il copie depuis le live vers le système installé `/etc/skel`
  (tous les réglages XFCE ci-dessus) et `/usr/share/xfcethemes`.
  **Openbox** : il garde le `/etc/skel` de `packarch-openbox` et n'y ajoute que
  ce qui ne dépend pas de XFCE (`.bashrc`, `.bash_profile`,
  `geany.conf`, SMPlayer), car `xfsettingsd` tourne aussi sous Openbox et
  appliquerait les réglages XFCE ; il fait d'Openbox la session par défaut de
  LightDM (`lightdm.conf.d/60-default-session.conf`). Dans les deux cas, il
  copie les thèmes GTK/icônes qui n'appartiennent à aucun paquet, ainsi que `/etc/X11/xorg.conf.d/10-no-blanking.conf`, `/etc/lightdm/lightdm.conf.d/40-numlock.conf` et les hooks
  `90-geany-new-instance.hook` et `90-hide-desktop-entries.hook` (qu'il applique aussi tout de suite). Il crée aussi `/etc/sudoers.d/90-wheel-nopasswd`
  (`%wheel  ALL=(ALL) NOPASSWD: ALL`) : **`sudo` sans mot de passe** sur le
  système installé. Le nom en `90-` le fait lire après le `10-installer` de
  Calamares (`%wheel ALL=(ALL) ALL`), car c'est la dernière règle qui compte.
  Enfin, si **rustup** a été coché, il lance `rustup default stable` sous le
  nom de l'utilisateur créé (Calamares passe `${USER}` en second argument) :
  la toolchain stable est téléchargée dans son dossier personnel et activée.
  Un échec (pas de réseau) ne fait pas échouer l'installation. Délai de
  l'étape porté de 10 à 30 minutes pour ce téléchargement.
- **Configuration de GitHub au premier login** : `apply-live-config` copie
  aussi `/usr/local/bin/github-setup`, l'archive chiffrée
  `/usr/share/github-setup/myEncryptedFile` (clé SSH GitHub et `gitconfig.sh`,
  chiffrée avec cryptyrust, embarquée dans l'ISO) et l'entrée
  `/etc/xdg/autostart/github-setup.desktop` (`OnlyShowIn=XFCE;OPENBOX;` :
  Openbox la lance aussi, par `openbox-xdg-autostart`). À l'ouverture de session,
  une fenêtre zenity demande le mot de passe de l'archive ; `github-setup` la
  déchiffre dans `$XDG_RUNTIME_DIR` (en RAM ; mot de passe transmis par un
  tube, jamais en argument), l'extrait dans le dossier personnel, met
  `~/.ssh` en 700 et les clés privées en 600, puis lance `~/gitconfig.sh`.
  Mot de passe faux : redemandé. Annuler : « Plus tard » (redemandé à la
  prochaine session) ou « Ne plus demander ». Une fois terminé, le fichier
  `~/.config/github-setup.done` empêche toute nouvelle demande ; journal dans
  `~/.cache/github-setup.log`. Sur le live, rien n'est lancé (l'entrée
  autostart n'est installée que sur le système installé). `zenity` est
  ajouté au groupe du bureau de `netinstall_live.conf` (`cryptyrust` y était
  déjà). **Seule la version chiffrée est sur l'ISO** : pour changer de clé,
  remplacer `archiso/airootfs/usr/share/github-setup/myEncryptedFile`
  (archive `.tar.gz` chiffrée avec `cryptyrust -e`, extraite dans le dossier
  personnel).
- `packages_online.conf` (d'origine) fait un `pacman -Syu` après l'installation
  des paquets : **le système installé est à jour**.

### Bureau Openbox (Packarch)

Le choix « Openbox » installe `packarch-openbox` depuis [packarch] (sources :
[myrepo-pkgs](https://github.com/Antidote1911/myrepo-pkgs), licence GPL3) :
polybar ou tint2, menus rofi, dunst, plank, picom, kitty et 15 thèmes, changés depuis
le menu du bureau. La configuration est reprise de la version GPL3 de la
configuration Openbox d'Aditya Shakya (7.0-9) ; la version premium (licence
DBAD : 15 thèmes de plus et la fonction « Changer les couleurs ») n'est plus
utilisée. Ses dépendances sont aussi dans [packarch] : `packarch-skin`,
`packarch-themes`, `packarch-icons`, `packarch-cursors`, `packarch-fonts`,
`packarch-backgrounds` et les paquets AUR
(`nitrogen`, `xfce-polkit`, `lead-git`, `skippy-xd-git`, `ksuperkey`,
`betterlockscreen`, `networkmanager-dmenu-git`, `light`…). L'ancien
`packarch-openbox-extras` (`packarch-tcma`, `packarch-reload-theme`, icônes de
dunst) est fusionné dans `packarch-openbox` depuis la 7.0-16 (`replaces`) ;
ses illustrations (`/usr/share/packarch/artworks`), utilisées nulle part, sont
supprimées.

**Sélecteur de thèmes `packarch-skin`** (Rust, sources dans
`myrepo-pkgs/packarch-skin`) : chaque thème est un dossier de
`~/.config/openbox/themes` avec ses dispositions (`polybar/`, `rofi/`, `tint2/`),
son fond d'écran et un `theme.toml` qui le décrit : couleurs
(valeurs, références à d'autres couleurs, `lighten()`/`darken()`), rôles des
couleurs dans la barre, rofi et dunst, polices, thèmes GTK/icônes/curseur,
thème et marges d'Openbox, dunst, plank, picom. Il remplace les scripts
`theme.bash`, `apply.sh` (un par thème), `launch-bar.sh`, `polybar.sh`,
`tint2.sh` et `polybar/launch.sh` :

| Commande | Effet |
|---|---|
| `packarch-skin apply [THÈME]` | applique un thème (par défaut le courant) : fichiers de couleurs de polybar et rofi, kitty, Geany, GTK (xfconf, gsettings), `rc.xml` d'Openbox, dunst, plank (dconf), picom, fond d'écran (nitrogen), puis relance la barre |
| `packarch-skin bar [polybar\|tint2]` | relance la barre du thème courant, et change de barre si on en donne une (retenue dans `themes/.panel`, polybar par défaut) ; détecte au premier lancement de polybar la batterie, l'adaptateur, le rétroéclairage et l'interface réseau (`/sys`) |
| `packarch-skin list`, `current`, `wallpaper`, `check` | thèmes, thème courant, fond d'écran, vérification des `theme.toml` |
| `packarch-skin openbox-menu` | menu « Changer de style » d'Openbox |

Les `theme.toml` ont été générés depuis les `theme.bash` : couleurs écrites
identiques à celles d'`apply.sh` (vérifié sur les 15 thèmes), à une
différence près : l'ancien `sed` de `width =` de dunst modifiait aussi
`progress_bar_*_width`, plus maintenant. `PACKARCH_SKIN_DRY=1` affiche les
commandes au lieu de les lancer (tests).

Modifications de la configuration d'origine :
- **noms Packarch** partout : chemins `/usr/share/packarch` (au lieu de
  `/usr/share/archcraft`), commandes `packarch-reload-theme` et `packarch-tcma`
  (réduites à Openbox ; `archcraft-session`, inutilisé, retiré), pipemenus
  `pa-*`, thèmes d'icônes `Packarch(-Dark)`, police d'icônes `packarch`
  (famille renommée dans le fichier). Les mentions d'auteur (Aditya Shakya)
  sont conservées ;
- **thèmes appliqués par `packarch-skin`** (ci-dessus) ;
- **kitty seul terminal** (raccourcis, menus, dock plank, polybar,
  `networkmanager-dmenu`, obmenu-generator, `ob-music`, `ob-furminal`,
  « Ouvrir un terminal ici » de Thunar) : alacritty et xfce4-terminal ne sont
  plus installés, le menu « Couleurs du terminal » (schémas d'alacritty) est
  retiré, « Changer de police » modifie `~/.config/kitty/fonts.conf`. Super+Entrée
  et Ctrl+Alt+T ouvrent kitty (Super+Maj+Entrée, en double, retiré) ;
- **deux styles de menu seulement**, « Icônes » (par défaut) et « Glyphes » :
  `menu-simple.xml` et `menu-minimal.xml` supprimés, les thèmes qui les
  utilisaient (easy, gray, hack, kiss, rainy, slime) passent à « Glyphes » ;
- **pavé numérique allumé** à l'ouverture de session, comme sous XFCE :
  `keyboards.xml` (`Numlock` à `true`), appliqué par xfsettingsd ;
- **nano au lieu de vim, plus de ranger** : Ctrl+Alt+V ouvre nano dans
  kitty (plus d'entrée nano dans « Applications en root » depuis 7.0-18) ;
  ranger (Ctrl+Alt+R, menu root) retiré ;
- **Plank toujours accessible** : `hide_mode = "intelligent"` dans les 15
  thèmes (avant : `auto` sauf default et nord, dock toujours caché, souvent
  sur le bord droit) ; visible tant qu'aucune fenêtre ne le recouvre, donc les
  fenêtres réduites restent visibles (7.0-18) ;
- **Menu « Glyphes » aligné** : la police des éléments de menu est
  « police du thème,feather » (`rc.xml`, `packarch-skin` 1.0.0-3, menu
  « Changer de police ») : les codes des glyphes existent aussi dans d'autres
  polices d'icônes, de largeurs différentes ; « Favoris Internet » utilise le
  signet de feather au lieu du globe Font Awesome (7.0-19) ;
- **tint2** : retiré en 7.0-15 puis rétabli en 7.0-21 (`packarch-skin`
  1.0.0-4) : dispositions `tint2/` des thèmes, scripts `tint2-*`, dépendance,
  menu « Panneau / Barre » pour passer de polybar à tint2 ; lanceur kitty au
  lieu d'alacritty, bouton `distributor-logo-archlinux` au lieu du logo des
  illustrations supprimées ;
- **horloge en 24 h** dans les 15 thèmes : `%I:%M %p` remplacé par `%H:%M`
  dans les modules `date` de polybar, dates dans
  l'ordre français (`%d %b %Y`, sans le `It's`/`at` anglais), et
  `locale = ${env:LANG:fr_FR.UTF-8}` dans chaque `config.ini` (polybar ignore
  la langue du système sans cette option : jours et mois en anglais) ; même chose
  pour la date du menu « Infos système » (`pa-sysinfo`). L'écran de
  verrouillage reçoit `time_format="%H:%M"` (`/etc/betterlockscreenrc`) ;
- **traduction en français** de ce qui s'affiche : menus Openbox
  (`menu-*.xml`), pipemenus et `menulib/packarch.cfg`
  (`/usr/share/packarch/openbox`), scripts de `~/.config/openbox/scripts`
  (menus rofi, notifications), scripts polybar des thèmes, libellés polybar
  (hors ligne, muet…), textes des thèmes rofi (« Rechercher... », « Mot de
  passe »…), catégories d'obmenu-generator (`schema.pl`), actions
  personnalisées de Thunar (`uca.xml`) et textes de betterlockscreen
  (`/etc/betterlockscreenrc`). Seuls les textes affichés sont traduits : les
  sorties de `bluetoothctl`, `mpc` ou `playerctl` comparées par les scripts,
  les commentaires et les noms de fichiers restent en anglais.
  `networkmanager-dmenu` n'est pas traduit ;
- **Favoris Internet** : section du menu sous « Applications en root »,
  sous-menu `pa-bookmarks` qui lit
  `~/.config/openbox/favoris.txt` : une ligne `Nom:adresse` par favori (coupée
  au premier `:`), `-` pour un séparateur, `#` pour un commentaire ; ouvert
  avec `xdg-open`. « Modifier les favoris » ouvre le fichier (`exo-open`) ;
- `menulib/packarch.cfg` : `shopt -u patsub_replacement`. Depuis bash 5.2, le
  `&` du remplacement de `${var//motif/remplacement}` vaut le texte trouvé :
  `XMLescape` produisait `'apos;` au lieu de `&apos;` (libellés et commandes
  des sous-menus contenant `'`, `"`, `<` ou `>` cassés) ;
- `autostart` : au premier login, `packarch-skin apply` applique le thème
  courant (`default`), puis `betterlockscreen` prépare les images de son fond
  d'écran ; le fichier `~/.config/openbox/themes/.applied` évite de le
  refaire ;
- `autostart` : ne lance plus `xfce-polkit`, déjà démarré par l'autostart XDG
  (`/etc/xdg/autostart/xfce-polkit.desktop`, via `openbox-xdg-autostart`) ;
  deux instances donnaient « An authentication agent already exists » ;
- fichiers XML de xfconf et Thunar : le commentaire de copyright placé avant
  la déclaration XML est retiré ;
- pas de script `.install` : Calamares copie lui-même `/etc/skel`.

`calamares-online.sh` (lancé par CachyOS Hello) garde le rafraîchissement du
trousseau de clés, mais **ne réinstalle plus `cachyos-calamares-next` depuis le
dépôt CachyOS** au lancement, ce qui remplacerait notre version. Il écrit
aussi la sortie de Calamares dans `/home/liveuser/cachy-install.log`.

### Installation hors ligne (conservée, non utilisée)

`settings_offline.conf` copie le système live au lieu de télécharger les
paquets. Il a été corrigé et reste disponible :

- `shellprocess@cleanup_live` lance `/usr/local/bin/cleanup-live-iso` juste
  après la copie : retire les réglages du live (accès `sudo`/polkit sans mot de
  passe, connexion automatique de `tty1`, connexion root SSH, hooks archiso de
  l'initramfs, services du live), copie les noyaux dans `/boot`, initialise le
  trousseau pacman ;
- `netinstall@offline` : les mêmes cases à cocher et catégories (sans Système), installées si Internet est
  disponible (test de connexion ajouté à `welcome.conf`, non bloquant ;
  `update_db: true` dans `packages_offline.conf`) ;
- `grubcfg` ajouté ; GRUB par défaut (Limine n'est pas sur l'ISO).

### Autres corrections dans `live-offline.patch`

- `bootloader/main.py` et `grubcfg/main.py` : sans page de choix du chargeur,
  utilisent GRUB au lieu de ne rien installer.
- `users/users.conf` : shell de l'utilisateur créé `/bin/zsh` au lieu de
  `/bin/bash`.
- `src/scripts/shell-setup` : choisit zsh avant fish (`chsh` à la fin de
  l'installation, après `users.conf`), pour garder le shell du live.
- `pacstrap/main.py` : installe `linux-cachyos` et ses en-têtes seulement,
  sans `linux-cachyos-lts` (ni `linux-cachyos-lts-zfs` sur ZFS), que le module
  ajoutait d'office.
- `shellprocess.conf` : `~/.xprofile` n'est plus supprimé du dossier de
  l'utilisateur (nécessaire au fond d'écran), et `cachyos-calamares-next` est
  désinstallé à la toute fin (installation hors ligne).

### `removeun` (script d'origine, mode hors ligne)

`boost-libs`, `yaml-cpp` et `squashfs-tools` retirés de sa liste : il les
désinstallait avec `pacman -Rsnc` (cascade), ce qui supprimait Calamares en
pleine installation. `clonezilla` retiré aussi (plus sur l'ISO), et sans carte
NVIDIA il retire `linux-cachyos-nvidia-open` au lieu de
`linux-cachyos-lts-nvidia-open`.

### Mettre à jour Calamares

Quand CachyOS publie une nouvelle version :

```bash
git clone -b cachyos-dev https://github.com/CachyOS/cachyos-calamares calamares-src
cd calamares-src
git apply ../calamares/live-offline.patch     # corriger les conflits éventuels
git add -A && git commit -m "Install the XFCE live ISO"
git format-patch -1 --stdout > ../calamares/live-offline.patch
git rev-parse HEAD~1                          # nouveau commit de base
```

Puis, dans `calamares/PKGBUILD`, mettre à jour `_commit` (et `pkgver`/`pkgrel`
d'après le PKGBUILD de CachyOS), et relancer `./build.sh`.

---

## 7. Liste des fichiers modifiés ou ajoutés

Hors fichiers générés à chaque build (`etc/motd`, `etc/environment`,
`etc/version-tag`, `etc/edition-tag`, `etc/pacman.d/cachyos-mirrorlist`,
`etc/systemd/system/display-manager.service`,
`etc/systemd/system/cachyos-rate-mirrors.timer`, `archiso/packages.x86_64`).

| Fichier | État |
|---|---|
| `MODIFS.md` | ajouté (ce document) |
| `build.sh` | ajouté (reconstruction complète) |
| `run.sh` | ajouté (test dans QEMU, live ou système installé) |
| `buildiso.sh`, `util*.sh` | déplacés dans `scripts/` ; `buildiso.sh` trouve la racine du dépôt depuis son emplacement |
| `scripts/util-iso.sh` | LightDM ; dépôt local Calamares |
| `scripts/makepkg-generic.conf` | ajouté (compilation en x86-64 générique) |
| `reset.sh`, `.gitignore` | ajoutés (nettoyage du projet) |
| `testiso.sh`, `ci.build.sh`, `lddd.sh`, `machines/`, `testcases/` | supprimés |
| `calamares/PKGBUILD`, `calamares/live-offline.patch`, `calamares/build.sh` | ajoutés |
| `localrepo/` | généré par `calamares/build.sh` |
| `archiso/packages_desktop.x86_64` | KDE → XFCE et applications, `cachyos-zsh-config`, sans noyau LTS ni outils de secours |
| `archiso/grub/`, `archiso/syslinux/`, `archiso/efiboot/`, `airootfs/etc/mkinitcpio.d/linux.preset` | `linux-cachyos` seul |
| `archiso/airootfs/etc/passwd` | zsh pour `root` et `liveuser` |
| `archiso/airootfs/root/.zshrc` | ajouté (configuration zsh CachyOS pour root) |
| `archiso/profiledef.sh` | permissions 755 de `cleanup-live-iso`, `apply-live-config`, `live-fit-display`, `github-setup`, `hide-desktop-entries`, `theme-switcher.sh`, `init-backdrop.sh` |
| `archiso/airootfs/etc/locale.conf`, `locale.gen`, `vconsole.conf`, `localtime`, `X11/xorg.conf.d/00-keyboard.conf` | français, `Europe/Paris` |
| `archiso/airootfs/etc/lightdm/lightdm.conf.d/50-cachyos-live.conf` | ajouté (connexion automatique) |
| `archiso/airootfs/etc/X11/xorg.conf.d/10-no-blanking.conf` | ajouté (pas d'extinction de l'écran) |
| `archiso/airootfs/etc/lightdm/lightdm.conf.d/40-numlock.conf` | ajouté (pavé numérique allumé sur l'écran de connexion) |
| `archiso/airootfs/etc/pacman.d/hooks/40-cachyos-live-locale-gen.hook` | ajouté |
| `archiso/airootfs/etc/pacman.d/hooks/90-geany-new-instance.hook` | ajouté (Geany en nouvelle instance) |
| `archiso/airootfs/etc/pacman.d/hooks/90-hide-desktop-entries.hook`, `usr/local/bin/hide-desktop-entries` | ajoutés (entrées cachées des menus) |
| `archiso/airootfs/etc/pacman.d/hooks/80-cachyos-live-xfce-skel.hook` et `.sh` | ajoutés |
| `archiso/airootfs/etc/pacman.d/hooks/90-cachyos-live-kwin-keyboard.hook` | supprimé |
| `archiso/airootfs/etc/plasmalogin.conf`, `plasmalogin.conf.d/` | supprimés |
| `archiso/airootfs/etc/skel/.config/` (réglages KDE) | supprimés |
| `archiso/airootfs/etc/skel/.config/xfce4/…`, `smplayer/`, `geany/`, `xfcethemes/`, `.xprofile` | ajoutés |
| `archiso/airootfs/usr/share/xfcethemes/` | ajouté (sélecteur de thèmes) |
| `archiso/pacman.conf` | dépôt `[packarch]` (build) |
| `archiso/airootfs/etc/pacman.conf`, `etc/pacman-more.conf` | dépôt `[packarch]` |
| `archiso/airootfs/etc/pacman.d/packarch-mirrorlist` | ajouté |
| `archiso/airootfs/usr/local/bin/calamares-online.sh` | modifié |
| `archiso/airootfs/usr/local/bin/apply-live-config` | ajouté |
| `archiso/airootfs/usr/local/bin/live-fit-display` | ajouté (bouton du live) |
| `archiso/airootfs/usr/local/bin/github-setup` | ajouté (configuration de GitHub au premier login) |
| `archiso/airootfs/usr/share/github-setup/` | ajouté (archive chiffrée, entrée autostart) |
| `archiso/airootfs/usr/local/bin/cleanup-live-iso` | ajouté |
| `archiso/airootfs/usr/local/bin/removeun` | modifié |
| `archiso/airootfs/usr/local/bin/removeun-online` | modifié |

---

## 8. Points connus

- **Build à cheval sur minuit** : le renommage final échoue (`mv: cannot stat
  …`), car `scripts/buildiso.sh` cherche un fichier daté du jour de fin. L'ISO est
  quand même produite sous le nom `out/desktop/cachyos-AAAA.MM.JJ-x86_64.iso`
  (date de début). Défaut du script d'origine, non corrigé.
- **Message `ERROR: An unknown error has occurred` en fin de build** : affiché à
  chaque build réussi par le piège `EXIT` de `scripts/buildiso.sh` (d'origine) ; le code
  de sortie est 0.
- **Installation en ligne** : nécessite Internet (CachyOS Hello le vérifie avant
  de lancer l'installeur). Elle télécharge tout le système (environ 3 Go).
- **`vim`** reste installé (dépendance de `cachyos-zsh-config`).
- **Bureau Openbox** : l'ISO grossit d'environ 130 Mo (dépôt local). Les
  paquets `-git` (`lead-git`, `skippy-xd-git`, `networkmanager-dmenu-git`)
  prennent la version du jour de leur compilation. Les captures d'écran de la
  page « Bureau » sont celles de CachyOS (`/etc/calamares/images/xfce.jxl`,
  `openbox.jxl`).
- **Mise à jour de Calamares** : notre version ne suit pas automatiquement
  celle de CachyOS (voir [Mettre à jour Calamares](#mettre-à-jour-calamares)).


#!/bin/sh
# remove from airootfs!
# Called by 80-cachyos-live-xfce-skel.hook: adds live-only properties to the
# xfconf files shipped in /etc/skel by cachyos-xfce-settings.
P=/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml

sed -i '/<property name="xfce4-power-manager" type="empty">/a\
    <property name="dpms-enabled" type="bool" value="false"/>\
    <property name="blank-on-ac" type="int" value="0"/>\
    <property name="blank-on-battery" type="int" value="0"/>\
    <property name="inactivity-on-ac" type="uint" value="14"/>\
    <property name="inactivity-on-battery" type="uint" value="14"/>\
    <property name="lock-screen-suspend-hibernate" type="bool" value="false"/>' \
    "$P/xfce4-power-manager.xml"

sed -i -e '/<property name="saver" type="empty">/a\
    <property name="enabled" type="bool" value="false"/>\
    <property name="idle-activation" type="empty">\
      <property name="enabled" type="bool" value="false"/>\
    </property>' \
    -e '/<property name="lock" type="empty">/a\
    <property name="enabled" type="bool" value="false"/>\
    <property name="sleep-activation" type="bool" value="false"/>' \
    "$P/xfce4-screensaver.xml"

sed -i '/<\/channel>/i\
  <property name="shutdown" type="empty">\
    <property name="LockScreen" type="bool" value="false"/>\
  </property>' \
    "$P/xfce4-session.xml"

# Geany is the only graphical text editor on the ISO (mousepad is not installed)
sed -i 's/=mousepad\.desktop/=geany.desktop/' /etc/skel/.config/mimeapps.list

# cachy-browser is not on the ISO: use Firefox for the panel launcher, the
# whisker menu favorites and the default browser
cp /usr/share/applications/firefox.desktop \
    /etc/skel/.config/xfce4/panel/launcher-20/15657829162.desktop
sed -i 's/^WebBrowser=.*/WebBrowser=firefox/' /etc/skel/.config/xfce4/helpers.rc
sed -i -e 's/cachy-browser\.desktop/firefox.desktop/' \
    -e 's/org\.xfce\.Parole\.desktop,//; s/epdfview\.desktop,//' \
    -e 's/galculator\.desktop/liloucalc.desktop/' \
    /etc/skel/.config/xfce4/panel/whiskermenu-1.rc

# galculator is not on the ISO: LilouCalc for the calculator key
sed -i 's|\(<property name="XF86Calculator" type="string" value="\)galculator"|\1LilouCalc"|' \
    "$P/xfce4-keyboard-shortcuts.xml"

# Theme switcher (/usr/share/xfcethemes): add a multi-item launcher
# (plugin-30, items in launcher-30/) after the system monitor launcher
sed -i -e '/<value type="int" value="21"\/>/a\
        <value type="int" value="30"/>' \
    -e '/^  <property name="plugins" type="empty">/a\
    <property name="plugin-30" type="string" value="launcher">\
      <property name="move-first" type="bool" value="true"/>\
      <property name="items" type="array">\
        <value type="string" value="theme-default.desktop"/>\
        <value type="string" value="theme-blue.desktop"/>\
        <value type="string" value="theme-gray.desktop"/>\
        <value type="string" value="theme-green.desktop"/>\
        <value type="string" value="theme-purple.desktop"/>\
        <value type="string" value="theme-red.desktop"/>\
        <value type="string" value="theme-yellow.desktop"/>\
      </property>\
    </property>' \
    /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml

# Live only: "Ajuster la résolution" launcher (plugin-31, launcher-31/) after
# the theme switcher, runs /usr/local/bin/live-fit-display. apply-live-config
# removes it from /etc/skel of the installed system.
sed -i -e '/<value type="int" value="30"\/>/a\
        <value type="int" value="31"/>' \
    -e '/^  <property name="plugins" type="empty">/a\
    <property name="plugin-31" type="string" value="launcher">\
      <property name="items" type="array">\
        <value type="string" value="live-fit-display.desktop"/>\
      </property>\
    </property>' \
    /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml

# Start directly on the "default" theme of the theme switcher (same values as
# /usr/share/xfcethemes/theme-switcher.sh --default), so that the script does
# not have to run at login
sed -i -e 's|\(<property name="ThemeName" type="string" value="\)[^"]*"|\1Arc-Dark"|' \
    -e 's|\(<property name="IconThemeName" type="string" value="\)[^"]*"|\1Luna-Purple-Dark"|' \
    -e 's|\(<property name="CursorThemeName" type="string" value="\)[^"]*"|\1Qogir-Dark"|' \
    "$P/xsettings.xml"
sed -i 's|\(<property name="theme" type="string" value="\)[^"]*"|\1Arc-Dark"|' "$P/xfwm4.xml"
sed -i 's|/usr/share/wallpapers/cachyos-wallpapers/Dimensions\.png|/usr/share/backgrounds/xfce-default.png|g' \
    "$P/xfce4-desktop.xml"
# xfce4-terminal migrates terminalrc to its xfconf channel on first start
T=/etc/skel/.config/xfce4/terminal/terminalrc
sed -i '/^Color\(UseTheme\|Foreground\|Background\|CursorUseDefault\|Cursor\|BoldUseDefault\|Bold\|Palette\)=/d; /^TabActivityColor=/d' "$T"
cat >> "$T" <<'TERM'
ColorUseTheme=FALSE
ColorForeground=#e8e8e8
ColorBackground=#1c1024
ColorCursorUseDefault=FALSE
ColorCursor=#9333EA
ColorBoldUseDefault=FALSE
ColorBold=#9333EA
ColorPalette=#000000;#cc0000;#4e9a06;#c4a000;#3465a4;#75507b;#06989a;#d3d7cf;#555753;#ef2929;#8ae234;#fce94f;#729fcf;#ad7fa8;#34e2e2;#eeeeec
TabActivityColor=#9333EA
TERM

# Turn the numeric keypad on when the session starts
sed -i 's|\(<property name="Numlock" type="bool" value="\)false"|\1true"|' "$P/keyboards.xml"

# Thunar panel launcher: "default-folder" only exists in a few icon themes,
# org.xfce.thunar is in every theme of the switcher and in hicolor
sed -i 's/^Icon=default-folder$/Icon=org.xfce.thunar/' \
    /etc/skel/.config/xfce4/panel/launcher-22/15657829254.desktop

# Thunar custom actions:
# - "Thunar Root" and "Terminal root" (was "Open a root terminal here"): sudo
#   instead of pkexec (no password for the wheel group, see
#   /etc/sudoers.d/90-wheel-nopasswd on the installed system)
# - "Set as desktop background" removed: Thunar's wallpaper plugin already
#   has this entry (and the action wrote monitor0/image-path, which xfdesktop
#   4.20 no longer reads)
sed -i -e 's|<icon>stock_folder</icon>|<icon>folder-red</icon>|' \
    -e 's|<command>pkexec thunar %f</command>|<command>sudo thunar %f</command>|' \
    -e 's|<name>Open a root terminal here</name>|<name>Terminal root</name>|' \
    -e 's|<command>pkexec  xfce4-terminal --default-working-directory=%f</command>|<command>sudo xfce4-terminal --default-working-directory=%f</command>|' \
    /etc/skel/.config/Thunar/uca.xml
# Separate run: reading a whole <action> block skips the substitutions above
sed -i '/<action>/{:a;N;/<\/action>/!ba;/<name>Set as desktop background<\/name>/d}' \
    /etc/skel/.config/Thunar/uca.xml

# Thunar: menu bar hidden (Ctrl+M shows it), "Delete" (bypassing the trash)
# in the context menu
sed -i -e '/<property name="last-menubar-visible"/d' \
    -e '/<property name="misc-show-delete-action"/d' \
    -e '/<\/channel>/i\
  <property name="last-menubar-visible" type="bool" value="false"/>\
  <property name="misc-show-delete-action" type="bool" value="true"/>' \
    "$P/thunar.xml"

#!/bin/sh
# remove from airootfs!
# Called by 80-live-xfce-skel.hook: the XFCE settings come from
# packarch-xfce-settings; only the live-only "Ajuster la résolution" launcher
# (plugin-31, launcher-31/ in airootfs, runs /usr/local/bin/live-fit-display)
# is added here, after the theme switcher (plugin-30). The installed system
# gets the /etc/skel of packarch-xfce-settings, without it.
sed -i -e '/<value type="int" value="30"\/>/a\
        <value type="int" value="31"/>' \
    -e '/^  <property name="plugins" type="empty">/a\
    <property name="plugin-31" type="string" value="launcher">\
      <property name="items" type="array">\
        <value type="string" value="live-fit-display.desktop"/>\
      </property>\
    </property>' \
    /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml

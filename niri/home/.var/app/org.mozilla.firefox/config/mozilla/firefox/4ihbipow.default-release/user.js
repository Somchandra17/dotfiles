// Middle-click autoscroll. Linux leaves this off; Wayland then does nothing
// with the wheel button instead of showing the up/down cursor.
user_pref("general.autoScroll", true);
// Don't paste the primary selection on the same click that starts autoscroll.
user_pref("middlemouse.paste", false);

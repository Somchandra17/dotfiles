// Middle-click autoscroll. Linux leaves this off; Wayland then does nothing
// with the wheel button instead of showing the up/down cursor.
user_pref("general.autoScroll", true);
// Don't paste the primary selection on the same click that starts autoscroll.
user_pref("middlemouse.paste", false);
// NVIDIA blocklists dmabuf in Firefox, so PipeWire screen share only offers
// MemFd. niri 26.04 is dmabuf-only, so the share fails. Force dmabuf on.
// https://bugzilla.mozilla.org/show_bug.cgi?id=1985338
user_pref("widget.dmabuf.force-enabled", true);

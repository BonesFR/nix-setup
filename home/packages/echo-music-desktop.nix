# "Echoes" — EchoMusicApp/Echo-Music-Desktop, a Flutter-based ad-free YouTube
# Music client. Not in nixpkgs, ships only as AppImage/deb/rpm upstream, so
# this wraps the published AppImage rather than building Flutter from source
# (a from-source build would need a pinned Flutter SDK + pub dependency
# hashes and would be much higher-maintenance to keep working).
#
# To update: check https://github.com/EchoMusicApp/Echo-Music-Desktop/releases/latest
# for the new tag, bump `version`, then either run
# `nix-prefetch-url <new-url>` for the new sha256, or build with a dummy hash
# and copy the "got: sha256-..." value Nix reports on mismatch.
#
# The .desktop/icon filenames inside the AppImage aren't hardcoded here —
# they're discovered at build time with `find`, since the first guess
# (echo-music-desktop.desktop) turned out to be wrong for the real AppImage.
{ lib, pkgs, fetchurl, appimageTools }:

let
  pname = "echo-music-desktop";
  version = "1.0";
  src = fetchurl {
    url = "https://github.com/EchoMusicApp/Echo-Music-Desktop/releases/download/v${version}/EchoMusic.AppImage";
    sha256 = "f3e2b758f80c4603528e858d5983766ee87f63920c0b734beeea6cf48f2d0a2d";
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: with pkgs; [ mpv gtk3 hicolor-icon-theme ];

  extraInstallCommands = ''
    desktopFile=$(find ${appimageContents} -maxdepth 2 -iname '*.desktop' | head -n1)
    if [ -z "$desktopFile" ]; then
      echo "echo-music-desktop: no .desktop file found inside the AppImage — inspect ${appimageContents} manually" >&2
      exit 1
    fi

    install -m 444 -D "$desktopFile" "$out/share/applications/${pname}.desktop"
    # Rewrite whatever the Exec/Icon lines actually said to our wrapped binary name
    # and installed icon, regardless of what the upstream .desktop file used.
    sed -i \
      -e "s|^Exec=.*|Exec=${pname}|" \
      -e "s|^Icon=.*|Icon=${pname}|" \
      "$out/share/applications/${pname}.desktop"

    iconFile=$(find ${appimageContents} -maxdepth 3 \( -iname '*.png' -o -iname '*.svg' \) | head -n1)
    if [ -n "$iconFile" ]; then
      ext=''${iconFile##*.}
      install -m 444 -D "$iconFile" "$out/share/icons/hicolor/256x256/apps/${pname}.$ext"
    else
      echo "echo-music-desktop: no icon file found inside the AppImage — app will use a generic icon" >&2
    fi
  '';

  meta = with lib; {
    description = "Ad-free YouTube Music client with synced lyrics and offline playback";
    homepage = "https://github.com/EchoMusicApp/Echo-Music-Desktop";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}

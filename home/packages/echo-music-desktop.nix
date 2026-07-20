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
# Known risk: the .desktop/icon filenames below are inferred from the
# community AUR package for this same upstream project, not independently
# confirmed from the AppImage's real contents. If extraInstallCommands fails,
# run `appimageTools.extract` manually and inspect the result for the real
# filenames.
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
    install -m 444 -D ${appimageContents}/echo-music-desktop.desktop $out/share/applications/echo-music-desktop.desktop
    substituteInPlace $out/share/applications/echo-music-desktop.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}'
  '';

  meta = with lib; {
    description = "Ad-free YouTube Music client with synced lyrics and offline playback";
    homepage = "https://github.com/EchoMusicApp/Echo-Music-Desktop";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}

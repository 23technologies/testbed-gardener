{ pkgs ? import <nixpkgs> { } }:
let
  inherit (pkgs) lib buildGoPackage fetchFromGitHub;


in pkgs.mkShell {
  nativeBuildInputs = with pkgs;
    [
      awscli
      coreutils
      docker
      git
      gnumake
      gnused
      go
      iproute
      kops
      kubectl
      kubernetes-helm
      minikube
      openvpn
      protobuf
      screen
      terraform
      yaml2json
    ];
}

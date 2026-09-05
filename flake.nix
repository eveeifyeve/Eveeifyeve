{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      systems,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.git-hooks-nix.flakeModule
      ];

      flake.projectsList = [
        {
          owner = "Eveeifyeve";
          repo = "Dotfiles";
        }
        {
          owner = "TeaClientMC";
          repo = "Registry";
        }
        {
          owner = "nix-community";
          repo = "nix-user-chroot";
        }
      ];

      perSystem =
        {
          pkgs,
          lib,
          ...
        }:
        {
          treefmt.config = {
            projectRootFile = "flake.nix";
            flakeCheck = true;
            programs = {
              nixfmt.enable = true;
              statix.enable = true;
              mdsh.enable = true;
            };
          };

          pre-commit.settings.hooks = {
            treefmt.enable = true;
          };

          packages =
            let
              inherit (pkgs.writers) writeNuBin;
              opensource = lib.mapAttrsToList (k: v: "- ${k}: ${v}") {
                Nixpkgs = "Windows Enablement and Packaging Team Member & Nim Packaging Team Member";
              };
            in
            {
              roles = writeNuBin "gen-roles" ''
                                                let roles = (http get https://eveeifyeve.dev/api/roles | decode | from json)
                																let format_years = {|it|
                    let start = ($it | get -o startDate)
                    let end   = ($it | get -o endDate)
                    let start_year = if ($start | is-not-empty) { $start | split row "-" | last } else { null }
                    let end_year   = if ($end | is-not-empty) { $end | split row "-" | last } else { null }

                    if ($start_year | is-not-empty) and ($end_year | is-not-empty) {
                        if $start_year == $end_year {
                            $" \(($start_year)\)"
                        } else {
                            $" \(($start_year)-($end_year)\)"
                        }
                    } else {
                        ""
                    }
                }
                                                let business = (
                                                    $roles
                                                    | reduce -f {} {|it, acc|
                                                        let years = (do $format_years $it)
                                                        $acc | upsert $it.business $"($it.name)($years)"
                                                    }
                                                    | transpose key value
                                                    | each {|it| $"- ($it.key): ($it.value)"}
                                                    | str join ",\n"
                                                )

                                                let opensource = "${lib.concatStringsSep "\n" opensource}"
                                                print $"### Businesses\n($business)\n\n### Opensource Projects\n($opensource)"
              '';

              skillIcon = writeNuBin "gen-skills" ''
                let skills = (http get https://eveeifyeve.dev/api/skillIcon | decode | from json | str join ",")
                print $" <p align=\"center\"><a href=\"https://github.com/LelouchFR/skill-icons\"><img src=\"https://go-skill-icons.vercel.app/api/icons?i=($skills)&perline=13\" /></a></p>"
              '';

              pin-tags = writeNuBin "gen-pin-tags" ''
                let projects = ${builtins.toJSON self.projectsList}
                $projects | each { |p|
                  let file = ("profile/pin-" + $p.owner + "-" + $p.repo + ".svg")
                  "<a href=\"https://github.com/" + $p.owner + "/" + $p.repo + "\"><img src=\"" + $file + "\" height=\"150em\" width=\"412em\" align=\"center\" alt=\"" + $p.owner + "/" + $p.repo + "\" /></a>"
                }
                | str join "\n"
              '';
            };

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.mdsh
              (pkgs.python3.withPackages (python-pkgs: [
                python-pkgs.requests
              ]))
            ];
          };
        };
    };
}

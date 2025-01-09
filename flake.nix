{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  inputs.simintech.url = "github:gregorybednov/simintech_nix"; # /94cb0192edb8f42e21362dae2c3712a4cfa7d71e;
  inputs.mireadesktop.url = "github:gregorybednov/mireadesktop";
  inputs.stm32cubemx.url = "github:gregorybednov/stm32cubemx";
  inputs.gostfont.url = "github:gregorybednov/gostfont";
  inputs.nix-jetbrains-plugins.url = "github:gregorybednov/nix-jetbrains-plugins";
  inputs.mireapython.url = "github:gregorybednov/mireapython";

  outputs =
    {
      self,
      nixpkgs,
      simintech,
      stm32cubemx,
      ...
    }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit simintech;
          inherit stm32cubemx;
          inherit inputs;
        };
        modules = [
          ./configuration.nix
        ];
      };
    };
}

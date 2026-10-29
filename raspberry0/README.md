`sd-card.nix` is purely for creating a base image to flash to an sd card which will be configured with the real configuration. It's posted about in my blog post [here](http://blackolivepineapple.pizza/Building-cross-architecture-nixos-images.html). It's only here so that I have a better chance to find it if I end up needing it again :)

Apply the config with

```
nixos-rebuild switch -I nixos-config=configuration.nix --target-host jeff@raspberry0 --sudo --ask-elevate-password
```

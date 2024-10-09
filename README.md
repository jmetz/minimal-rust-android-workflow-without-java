# Overview 

This repo was inspired by https://www.reddit.com/r/rust/comments/17dr46y/comment/k60o3is/

It is an attempt to create minimal scaffold to generate android APK's 
without using the `gradle` build sytem, which is generally used by tools like
[`xbuild`](https://github.com/rust-mobile/xbuild) 
([NiklasEi's version](https://github.com/NiklasEi/xbuild)), 
[`cargo-mobile`](https://github.com/BrainiumLLC/cargo-mobile/)
/[`cargo-mobile2`](https://github.com/tauri-apps/cargo-mobile2)
, and the like.

## Prerequisites 

* A working android build system. You can chose to use Android Studio or go the 
  command-line route to install the needed tools, using eg `sdkmanager`. 
* A working rust build system with the required targets installed. I 
  recommend `rustup` to get this setup.  

## Workflow 

* `cargo ndk` to build `.so`s for the architectures you want to support
* `aapt2` to prepare the files to include in your APK and then zip them into an APK file
* `zipalign` to align the archive structure
* `apksigner` to sign with your key

Note; in principle, we can probably even remove `aapt2` and `zipalign`, 
as `aapt2` can be essentially replaced by `zip`, and `zipalaign` is optional.

However, as we _do need_ `apksigner` (AFAIK), there doesn't seem to be much 
point in removing the other _android build tools_.

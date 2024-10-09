#[cfg(target_os = "android")]
mod lib_android;
use log::info;

#[cfg(target_os = "android")]
use lib_android::main;
// #[cfg(target_os = "android")]
// pub use lib_desktop::main;

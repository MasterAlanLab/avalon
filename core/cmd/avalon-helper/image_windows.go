package main

// The build script seals this unique slot after linking. Installation checks
// the loaded value against the locked source file before copying any bytes.
// This does not replace Authenticode signing, which requires its own release
// integration because changing a sealed executable invalidates this digest.
var compiledImageSeal = "AVALON_HELPER_IMAGE_SHA256[0000000000000000000000000000000000000000000000000000000000000000]"

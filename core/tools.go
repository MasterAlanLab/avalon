//go:build tools

// Keeps the gomobile runtime in go.mod: `gomobile bind` needs it there.
package core

import _ "github.com/sagernet/gomobile"

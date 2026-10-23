package windowshost

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"errors"
)

const ImageSealPrefix = "AVALON_HELPER_IMAGE_SHA256["

// ValidateImage binds the bytes copied into Program Files to the already
// running, UAC-approved helper. It is not a publisher signature. The sole seal
// slot is excluded from the hash; the expected hash comes from the loaded
// process, rather than trusting the bytes at its possibly replaced filename.
func ValidateImage(body []byte, loadedSeal string) error {
	prefix := []byte(ImageSealPrefix)
	if len(loadedSeal) != len(prefix)+65 || !bytes.HasPrefix([]byte(loadedSeal), prefix) || loadedSeal[len(loadedSeal)-1] != ']' {
		return errors.New("invalid loaded helper image seal")
	}
	expected := loadedSeal[len(prefix) : len(prefix)+64]
	if expected == string(bytes.Repeat([]byte{'0'}, 64)) {
		return errors.New("the helper image is unsealed; rebuild it with core/build.sh")
	}
	if _, err := hex.DecodeString(expected); err != nil {
		return errors.New("invalid loaded helper image digest")
	}
	slot := -1
	for offset := 0; offset < len(body); {
		index := bytes.Index(body[offset:], prefix)
		if index < 0 {
			break
		}
		start := offset + index
		offset = start + len(prefix)
		end := offset + 64
		if end >= len(body) || body[end] != ']' {
			continue
		}
		if _, err := hex.DecodeString(string(body[offset:end])); err != nil {
			continue
		}
		if slot != -1 {
			return errors.New("the helper image has multiple digest slots")
		}
		slot = offset
	}
	if slot == -1 || string(body[slot:slot+64]) != expected {
		return errors.New("the source does not match the running helper image")
	}
	hash := sha256.New()
	_, _ = hash.Write(body[:slot])
	_, _ = hash.Write(bytes.Repeat([]byte{'0'}, 64))
	_, _ = hash.Write(body[slot+64:])
	if hex.EncodeToString(hash.Sum(nil)) != expected {
		return errors.New("the source does not match the running helper image")
	}
	return nil
}

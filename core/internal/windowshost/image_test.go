package windowshost

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"testing"
)

func TestImageCopyIsBoundToTheLoadedDigest(t *testing.T) {
	blank := bytes.Repeat([]byte{'0'}, 64)
	body := []byte("image-start:" + ImageSealPrefix + string(blank) + "]:image-end")
	digest := sha256.Sum256(body)
	seal := ImageSealPrefix + hex.EncodeToString(digest[:]) + "]"
	sealed := bytes.Replace(body, append(append([]byte(ImageSealPrefix), blank...), ']'), []byte(seal), 1)
	if err := ValidateImage(sealed, seal); err != nil {
		t.Fatal(err)
	}
	changed := append([]byte{}, sealed...)
	changed[0] ^= 1
	if err := ValidateImage(changed, seal); err == nil {
		t.Fatal("accepted source content replaced after elevation")
	}
	if err := ValidateImage(body, ImageSealPrefix+string(blank)+"]"); err == nil {
		t.Fatal("accepted an unsealed image")
	}
	if err := ValidateImage(append(sealed, []byte(seal)...), seal); err == nil {
		t.Fatal("accepted duplicate image digest slots")
	}
}

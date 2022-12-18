package myfuzz

import (
	"strings"
	"go.mozilla.org/sops/v3/aes"
)

func Fuzz(data []byte) int {
	key := []byte(strings.Repeat("f", 32))
	message := string(data)
	_, err := aes.NewCipher().Decrypt(message, key, "bar:")
	if err != nil {
		return 1
	}
	return 0
}


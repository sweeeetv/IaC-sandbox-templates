// generate the short string.
package keygen

import (
	"math/rand"
)

//62 -> 0-9, a-z, A-Z
const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
func GenerateShortUrl(length int) string {
	shortUrl := make([]byte, length)
	//need to initialize the size in Go, so the computer won't need to resize everytime
	for i := range shortUrl {
		//rand.IntN(len) picks a random index from charset
		shortUrl[i] = charset[rand.Intn(len(charset))]	
	}
	//example: 'aZ9kL2' if length = 6
	return string(shortUrl)

	//ok with lab not in production -> use hash-based or id-based generation, or check uniqueness before saving.
}
// data layer -> later becomes redis/table

// groups this file into a module called store.
package store

//a package is a workspace grouping files in the same dir.

//key -> abcdef, value -> long url, both are strings
// this like a dictionary. "abc123" -> "https://google.com"
// map, bigo O(1) for lookup, insert, delete. and unordered
var URLStore = make(map[string]string)	//initialize the map, must do before assign value.

//Redis SET - redis is an in-memory data store, it’s like a super fast database that lives in memory. It’s often used for caching and real-time applications. It’s like a key-value store, but it can also handle more complex data structures like lists, sets, and hashes. It’s great for storing data that needs to be accessed quickly, like session data or frequently accessed records. 
//redis is not used here
func Save(shortUrl string, url string) {
	//core
	URLStore[shortUrl] = url
}
//this lives in memory only, data will be wiped if app stops

//Redis GET
func Get(shortUrl string) (string, bool) {
	url, exists := URLStore[shortUrl] //looks up the key/shortUrl in the map and return the value if it exists
	return url, exists
}
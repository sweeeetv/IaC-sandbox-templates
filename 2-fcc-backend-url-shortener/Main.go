// main entry point for this executable
// Execution always kicks off in package main
package main //special, mandatory name, tells the Go compiler that the application starts here.
//If there is no main package, you have a library, not a runnable program.

import (
	"fcc-backend-url-shortener/handler"
	"net/http" //standard library, go already includes this in its global installation toolchain.
	//by convention, the last element of the import path is the package name. the 'net/http' package comprises files that begin with the statement 'package http'
	//use an alias if the last name is the same:
	//webhttp 'web/http'
)

func main(){
	http.HandleFunc("/api/shorturl/", handler.RedirectHandler)
	http.HandleFunc("/api/shorturl", handler.ShortenerHandler)
	http.ListenAndServe(":8080", nil)
}



//curl -X POST http://localhost:8080/api/shorturl -H "Content-Type: application/json"  -d '{"url":"https://google.com"}'

//curl -X POST http://localhost:8080/api/shorturl -H "Content-Type: application/json"  -d '{"url":"hdafsddfam"}'

//curl -X POST http://localhost:8080/api/shorturl/kPc74A -H "Content-Type: application/json"  -d '{"url":"https://google.com"}'


//http.Redirect(w, r, url, http.StatusPermanentRedirect)
// http logic
package handler

import (
	"encoding/json" //handles json data, converts between json and Go structs
	"fcc-backend-url-shortener/keygen"
	"fcc-backend-url-shortener/store"
	"log"
	"net/http" //starts server, define routes, read incoming req, send res.
	"net/url"
	"strings"
)

type Handler struct {
	Store *store.Store
}
func New(s *store.Store) *Handler {
	return &Handler{Store: s}
}

//define a new type struct named Req (similar to a class or object in other languages)
type Req struct {
	URL string `json:"url"` //A field named URL holds a string value
	//URL must be all cap to export, or its private. Go won’t allow encoding/decoding (important)
	//`json:"url"` -> struct tag (a metadata attached to the field), a mapping rule for json. -> “When reading JSON, look for a field called url and map it to URL” 
}


func (h *Handler) ShortenerHandler(w http.ResponseWriter, r *http.Request) {
	// var req Req
	// if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
	// 	http.Error(w, "invalid url", http.StatusBadRequest)
	// 	return
	// }
	// if _, err := url.ParseRequestURI(req.URL); err != nil {
	// 	http.Error(w, "invalid url", http.StatusBadRequest)
	// 	return
	// }
	if err := r.ParseForm(); err != nil {
		http.Error(w, "invalid url", http.StatusBadRequest)
		return
	}
	longUrl := r.FormValue("url") //this returns the first value for the named component of the query. If there are no values, it returns the empty string. It is equivalent to r.Form.Get("url") but more convenient if you only want the first value.


	u, err := url.ParseRequestURI(longUrl)
	// url.ParseRequestURI(longUrl) -> this function parses a raw URL string into a URL structure. It checks if the provided string is a valid absolute URL that can be routed over a network. If the URL is invalid, it returns an error.
	if  err != nil {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"error": "invalid url"})
		return
	}	

	if u.Scheme != "http" && u.Scheme != "https" { //this checks if the parsed URL has a scheme (like http or https). If the scheme is empty, it means the URL is not absolute, and the handler responds with an error message indicating that the URL is invalid.
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"error": "invalid url"})
		return
	}

	if !strings.Contains(u.Host, ".") { //this checks if the parsed URL has a valid host (domain). If the host is empty or does not contain a dot (.), it means the URL is not absolute, and the handler responds with an error message indicating that the URL is invalid.
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"error": "invalid url"})
		return
	}

	shortUrl := keygen.GenerateShortUrl(6)
	if err := h.Store.Save(r.Context(), shortUrl, longUrl); err != nil {
		log.Printf("failed to save url: %v", err) // fail loudly if this fails
		http.Error(w, "!failed to save url", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"original_url": longUrl, "short_url": shortUrl})
}

func (h *Handler) RedirectHandler(w http.ResponseWriter, r *http.Request) {
	shortUrl := strings.TrimPrefix(r.URL.Path, "/api/shorturl/")
	longUrl, exists, err := h.Store.Get(r.Context(), shortUrl)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	if !exists {
		http.Error(w, shortUrl+" not found", http.StatusNotFound)
		return
	}
	http.Redirect(w, r, longUrl, http.StatusPermanentRedirect)
}











//r is A pointer to a massive data struct in memory holding the incoming request data.
//bytes is written into w, directly adding them to the network response buffer.
// func ShortenerHandler(w http.ResponseWriter, r *http.Request){
// 	var req Req
// 	var shortUrl string
// 	//take json from the r.body, and turn it into a Go struct.

// 	//creates json decoder and reads from that stream directly from the req. then .Decode(&req) -> write the JSON into Req struct, 
// 	err := json.NewDecoder(r.Body).Decode(&req)  //method chaining
// 	if err != nil { 
// 		//http.StatusBadRequest == number 400
// 		http.Error(w, "invalid url", http.StatusBadRequest)
// 		return
// 	}

// 	//validates the string stored in req.URL is a fully formed, absolute URL that can be routed over a network.
// 	_, err = url.ParseRequestURI(req.URL) //from net/url package.
// 	if err != nil {
// 		http.Error(w, "invalid url", http.StatusBadRequest)
// 		return
// 	}

// 	shortUrl = keygen.GenerateShortUrl(6)
// 	store.Save(shortUrl, req.URL)
// 	w.Header().Set("Content-Type", "application/json") // Tells the client's web browser exactly what format to expect.
// 	response := map[string]string{
// 		"original_url": req.URL,
// 		"short_url": shortUrl,
// 	}
// 	json.NewEncoder(w).Encode(response)
// }

// func RedirectHandler(w http.ResponseWriter, r *http.Request){
// 	shortUrl := r.URL.Path[14:] // /abc123 -> abc123
// 	longUrl, exists := store.Get(shortUrl)
// 	if !exists {
// 		http.Error(w, shortUrl + " not found", http.StatusNotFound)
// 		return
// 	}
// 	http.Redirect(w, r, longUrl, http.StatusPermanentRedirect)
// }


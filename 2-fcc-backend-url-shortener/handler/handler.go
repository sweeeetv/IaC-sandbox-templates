// http logic
package handler

import (
	"encoding/json" //handles json data, converts/translates Go structs/maps - JSON.
	"fcc-backend-url-shortener/keygen"
	"fcc-backend-url-shortener/store"
	"net/http" //starts server, define routes, read incoming req, send res.
	"net/url"
)

//define a new type struct named Req (similar to a class or object shap in other languages)
type Req struct {
	URL string `json:"url"` //A field named URL holds a string value
	//URL must be all cap to export, or its private. Go won’t allow encoding/decoding (important)
	//`json:"url"`  -> struct tag (a metadata attached to the field), a mapping rule for json. -> “When reading JSON, look for a field called url and map it to URL” 
	//
}

//r is A pointer to a massive data struct in memory holding the incoming request data.
//You write bytes into w, directly adding them to the network response buffer.
func ShortenerHandler(w http.ResponseWriter, r *http.Request){
	var req Req
	var shortUrl string
	//take json from the r.body, and turn it into a Go struct.
	//json.NewDecoder(r.Body) -> creates json decoder and reads from that stream. reads directly from the req
	////.Decode(&req) -> write the JSON into Req struct, &req -> & needed so Go would update the actual struct.
	err := json.NewDecoder(r.Body).Decode(&req)  //method chaining
	if err != nil { 
		//Writing http.StatusBadRequest is exactly identical to typing the raw number 400.
		http.Error(w, "invalid url", http.StatusBadRequest)
		return
	}

	//validates the string stored in req.URL is a fully formed, absolute URL that can be routed over a network.
	_, err = url.ParseRequestURI(req.URL) //from net/url package.
	if err != nil {
		http.Error(w, "invalid url", http.StatusBadRequest)
		return
	}

	shortUrl = keygen.GenerateShortUrl(6)
	store.Save(shortUrl, req.URL)
	w.Header().Set("Content-Type", "application/json") // Tells the client's web browser exactly what format to expect.
	response := map[string]string{
		"original_url": req.URL,
		"short_url": shortUrl,
	}
	json.NewEncoder(w).Encode(response)
}

func RedirectHandler(w http.ResponseWriter, r *http.Request){
	shortUrl := r.URL.Path[14:] // /abc123 -> abc123
	longUrl, exists := store.Get(shortUrl)
	if !exists {
		http.Error(w, shortUrl + " not found", http.StatusNotFound)
		return
	}
	http.Redirect(w, r, longUrl, http.StatusPermanentRedirect)
}


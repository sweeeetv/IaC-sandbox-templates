// main entry point for this executable
// Execution always kicks off in package main
package main //special, mandatory name, tells the Go compiler that the application starts here.
//If there is no main package, you have a library, not a runnable program.

import (
	"context"
	"fcc-backend-url-shortener/handler"
	"fcc-backend-url-shortener/store"
	"log"
	"os"

	"net/http" //standard library, go already includes this in its global installation toolchain.

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/redis/go-redis/v9"
	//by convention, the last element of the import path is the package name. the 'net/http' package comprises files that begin with the statement 'package http'
	//use an alias if the last name is the same:
	//webhttp 'web/http'
)

func main() {
	ctx := context.Background() //this is a root context, which is never canceled, has no values, and has no deadline. It is typically used by the main function, initialization, and tests, and as the top-level Context for incoming requests.

	cfg, err := config.LoadDefaultConfig(ctx) // builds an AWS config object (region, credentials, retry settings)
	if err != nil {
		log.Fatalf("failed to load AWS config: %v", err) //can not connect to aws, usually because of missing credentials or misconfigured region. log.Fatalf() prints the message and exits the program with a non-zero status code.
	}
	dynamoClient := dynamodb.NewFromConfig(cfg) //ctg is the AWS SDK's configuration object, which contains all the information needed to make requests to AWS services. dynamodb.NewFromConfig(cfg) creates a new DynamoDB client using that configuration. This client is used to interact with DynamoDB, allowing the application to perform operations like reading and writing items in a DynamoDB table.

	tableName := os.Getenv("DYNAMO_TABLE")
	redisAddr := os.Getenv("REDIS_ADDR")
	if tableName == "" || redisAddr == "" {
		log.Fatal("DYNAMO_TABLE and REDIS_ADDR env vars must be set")
	} //this will appear
	rdb := redis.NewClient(&redis.Options{Addr: redisAddr}) //create a Redis client

	s := store.New(dynamoClient, tableName, rdb)
	h := handler.New(s)

	http.HandleFunc("/api/shorturl/", h.RedirectHandler)
	http.HandleFunc("/api/shorturl", h.ShortenerHandler)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK) //doesn't touch Dynamo/Redis — ALB health check must stay fast/independent
		w.Write([]byte("OK"))
	})

	log.Println("listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}












// func main(){
// 	http.HandleFunc("/api/shorturl/", handler.RedirectHandler)
// 	http.HandleFunc("/api/shorturl", handler.ShortenerHandler)
// 	http.HandleFunc("/health", func (w http.ResponseWriter, r*http.Request){
// 		w.WriteHeader(http.StatusOK)
// 		w.Write ([]byte("OK")) //
// 	})
// 	http.ListenAndServe(":8080", nil) //starts the web server, must be the last part.
// }


//test:
//curl -X POST https://d15208emiohrpu.cloudfront.net/api/shorturl -d '{"url":"https://google.com"}'
//curl -L localhost:8080/api/shorturl/<code>




//http.Redirect(w, r, url, http.StatusPermanentRedirect)
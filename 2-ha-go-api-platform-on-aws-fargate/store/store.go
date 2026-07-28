// data layer -> later becomes redis/table

// groups this file into a module called store.
package store

import (
	//Go's standard library
	"context"
	"errors"
	"time"

	//two third-party libraries: the AWS SDK for DynamoDB, and the Redis client.
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/redis/go-redis/v9"
)

//key: abcdef, value: long url, both are strings
//"abc123" -> "https://google.com"
//map, bigo O(1) for lookup, insert, delete. unordered


type Store struct {
// a pointer to the DynamoDB client (the object that actually talks to AWS over the network)
	dynamo   *dynamodb.Client 
// the name of the DynamoDB table
	table    string
// a pointer to the Redis client
	redis    *redis.Client 
	cacheTTL time.Duration
}
//The * means "pointer to." Client objects like this are meant to be shared and reused - rather than copying the whole thing around. Lowercase (dynamo, table) mean these fields are unexported — only code inside the store package can access them directly. That's Go's version of private.


//Go has no constructor keyword or new SomeClass() syntax — the convention is just a plain function, usually named New, that builds and returns the struct. &Store{...} creates a Store value and the & takes its address, returning a pointer (*Store) — matching what main.go expects when it does s := store.New(...).
func New(dynamoClient *dynamodb.Client, table string, redisClient *redis.Client) *Store {
	return &Store{dynamo: dynamoClient, table: table, redis: redisClient, cacheTTL: 24 * time.Hour}
} //in main.go -> s := store.New(dynamoClient, tableName, rdb)



// func (s *Store) Save(...) — the (s *Store) part is called a receiver. It means: "this function is a method attached to *Store, and inside the function body, s refers to the specific Store instance it was called on." This is Go's equivalent of this/self in other languages.
//context.Context: stop if connection stops.
func (s *Store) Save(ctx context.Context, shortUrl, longUrl string) error { //Go doesn't have exceptions. 
	_, err := s.dynamo.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(s.table),
		//Item is a field in the PutItemInput struct.
//map[string]int  --->> String : Integer
//map[string]types.AttributeValue --->> String : DynamoDB AttributeValue
		Item: map[string]types.AttributeValue{ //DynamoDB items are represented as a map from attribute name → typed value. 
			"url-shortener-short_id": &types.AttributeValueMemberS{Value: shortUrl},//string.
			"long_url":   &types.AttributeValueMemberS{Value: longUrl},
		},
	})
	if err != nil {
		return err // DynamoDB is the source of truth — fail loudly if this fails
	}

	// write-through cache — best effort, don't fail the request if Redis is briefly down
	_ = s.redis.Set(ctx, shortUrl, longUrl, s.cacheTTL).Err()
	return nil
}


//(s *Store) — receiver (method owner)
func (s *Store) Get(ctx context.Context, shortUrl string) (string, bool, error) { //(string, bool, error) is the return value
	// 1. cache first
	if val, err := s.redis.Get(ctx, shortUrl).Result(); err == nil {
		return val, true, nil
	}

	// 2. cache miss (or Redis error) — fall back to DynamoDB
	out, err := s.dynamo.GetItem(ctx, &dynamodb.GetItemInput{
		TableName: aws.String(s.table),
		Key:       map[string]types.AttributeValue{"url-shortener-short_id": &types.AttributeValueMemberS{Value: shortUrl}},
	})
	if err != nil {
		return "", false, err
	}
	if out.Item == nil {
		return "", false, nil
	}
	longUrlAttr, ok := out.Item["long_url"].(*types.AttributeValueMemberS)
	if !ok {
		return "", false, errors.New("malformed item in dynamodb")
	}

	_ = s.redis.Set(ctx, shortUrl, longUrlAttr.Value, s.cacheTTL).Err() // backfill cache
	//Set() returns a *redis.StatusCmd — a struct that wraps the whole result of the command (status, error, etc.) into one object. .Err() is a method on that struct that extracts just the error field from it.
	return longUrlAttr.Value, true, nil
}

//Redis SET - redis is an in-memory data store. It’s often used for caching and real-time applications. It’s like a key-value store, but it can also handle more complex data structures like lists, sets, and hashes. Great for storing data that needs to be accessed quickly, like session data or frequently accessed records. 


















// var URLStore = make(map[string]string)	//initialize the map, must do before assign value.

//redis is not used here
// func Save(shortUrl string, url string) {
// 	//core
// 	URLStore[shortUrl] = url
// }
// //this lives in memory only, data will be wiped if app stops

// //Redis GET
// func Get(shortUrl string) (string, bool) {
// 	url, exists := URLStore[shortUrl] //looks up the key/shortUrl in the map and return the value if it exists
// 	return url, exists
// }
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/go-resty/resty/v2"
)

func main() {
	lambda.Start(handler)
}

type AuthRequest struct {
	ClientId     string `json:"client_id"`
	ClientSecret string `json:"client_secret"`
}

type TokenResponse struct {
	AccessToken string `json:"access_token"`
	ExpiresIn   int64  `json:"expires_in"`
	TokenType   string `json:"token_type"`
}

func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	fmt.Println("Received Event")

	formData, err := url.ParseQuery(request.Body)
	if err != nil {
		return events.APIGatewayProxyResponse{StatusCode: 400}, err
	}

	clientID := formData.Get("client_id")
	clientSecret := formData.Get("client_secret")

	client := resty.New()

	r, _ := client.R().
		SetFormData(map[string]string{
			"client_id":     clientID,
			"client_secret": clientSecret,
			"grant_type":    "client_credentials",
		}).
		Post("https://apollo-domain-login.auth.us-east-1.amazoncognito.com/oauth2/token")

	if r.StatusCode() != 200 {
		return response(http.StatusUnauthorized, "authentication failed"), nil
	}

	var authRequest TokenResponse

	err = json.Unmarshal([]byte(r.Body()), &authRequest)

	if err != nil {
		return response(http.StatusBadRequest, "invalid request body"), nil
	}

	body, err := json.Marshal(authRequest)
	if err != nil {
		return response(http.StatusBadRequest, "invalid request body"), nil
	}

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
		Body: string(body),
	}, err
}

func response(statusCode int, message string) events.APIGatewayProxyResponse {
	body := map[string]interface{}{
		"message": message,
	}

	jsonBody, _ := json.Marshal(body)

	return events.APIGatewayProxyResponse{
		StatusCode: statusCode,
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
		Body: string(jsonBody),
	}
}

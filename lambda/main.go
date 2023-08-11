package main

import (
	"context"
	"encoding/json"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cognitoidentityprovider"
)

func main() {
	lambda.Start(handler)
}

type AuthRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type AuthReponse struct {
	AccessToken  string `json:"acess_token"`
	ExpiresIn    int64  `json:"expires_in"`
	TokenType    string `json:"token_type"`
	RefreshToken string `json:"refresh_token"`
}

func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var authRequest AuthRequest

	err := json.Unmarshal([]byte(request.Body), &authRequest)
	if err != nil {
		return response(http.StatusBadRequest, "invalid request body"), nil
	}

	session, err := session.NewSession()
	if err != nil {
		return response(http.StatusInternalServerError, "error creating AWS session"), nil
	}

	appClientID := os.Getenv("APP_CLIENT_ID")

	cognito := cognitoidentityprovider.New(session)

	authInput := &cognitoidentityprovider.InitiateAuthInput{
		AuthFlow: aws.String("USER_PASSWORD_AUTH"),
		ClientId: aws.String(appClientID),
		AuthParameters: map[string]*string{
			"USERNAME": aws.String(authRequest.Username),
			"PASSWORD": aws.String(authRequest.Password),
		},
	}

	authOutput, err := cognito.InitiateAuth(authInput)
	if err != nil {
		return response(http.StatusUnauthorized, "authentication failed"), nil
	}

	autuResponse := AuthReponse{
		AccessToken:  *authOutput.AuthenticationResult.AccessToken,
		ExpiresIn:    int64(*authOutput.AuthenticationResult.ExpiresIn),
		TokenType:    *authOutput.AuthenticationResult.TokenType,
		RefreshToken: *authOutput.AuthenticationResult.RefreshToken,
	}

	body, err := json.Marshal(autuResponse)
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

package main

import (
	"context"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func main() {
	lambda.Start(handler)
}

func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {

	/* sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))

	// Criar um cliente Cognito Identity Provider
	cognitoClient := cognitoidentityprovider.New(sess, aws.NewConfig().WithRegion("us-east-1")) // Substitua pela sua região

	// Nome de usuário do usuário do qual você deseja obter os atributos
	username := ""

	// Construir o input para obter os detalhes do usuário
	input := &cognitoidentityprovider.AdminGetUserInput{
		UserPoolId: aws.String(""),
		Username:   aws.String(username),
	}

	// Obter os detalhes do usuário
	_, err := cognitoClient.AdminGetUser(input)
	if err != nil {
		log.Fatal("Erro ao obter os detalhes do usuário:", err)
	} */

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
		Body: string("Message"),
	}, nil
}

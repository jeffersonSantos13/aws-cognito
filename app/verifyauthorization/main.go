package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/verifiedpermissions"
)

var (
	policyStoreID = "XEwbjSBXysrRurMvrud8Ho"
)

type CognitoToken struct {
	Sub   string `json:"sub"`
	Scope string `json:"scope"`
}

func NewEntityIdentifier(entityType string, entityId string) *verifiedpermissions.EntityIdentifier {
	return &verifiedpermissions.EntityIdentifier{
		EntityType: &entityType,
		EntityId:   &entityId,
	}
}

func NewActionIdentifier(actionType string, actionId string) *verifiedpermissions.ActionIdentifier {
	return &verifiedpermissions.ActionIdentifier{
		ActionType: &actionType,
		ActionId:   &actionId,
	}
}

func createSession() *session.Session {
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))
	return sess
}

func stringRef(s string) *string {
	return &s
}

func main() {
	token := "eyJraWQiOiJLU1A1ZkFBZUMwcXBPNnErYW0wU280T054bkdJQit0UURMZHV3RDBFMEFnPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIyMHRpNnIzZTc5aHZiamFocGJtZWdpMGl2bSIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoiYXBvbGxvXC93cml0ZSBhcG9sbG9cL3JlYWQiLCJhdXRoX3RpbWUiOjE2OTIzOTI4MDcsImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC51cy1lYXN0LTEuYW1hem9uYXdzLmNvbVwvdXMtZWFzdC0xX0NKQ093azB0RyIsImV4cCI6MTY5MjQwMzYwNywiaWF0IjoxNjkyMzkyODA3LCJ2ZXJzaW9uIjoyLCJqdGkiOiIxMTdjMGVhYy01NjQyLTQ1YjQtOGE1OS1mYjE2NDk0NDZkOGEiLCJjbGllbnRfaWQiOiIyMHRpNnIzZTc5aHZiamFocGJtZWdpMGl2bSJ9.Kth8oG2yFNnPr0mV69HCTr3_eRjkDuqa__dxEZAOUbvcRDju3jUSSYOHfIZajJZ2l3DnJpvnXyJZ2vLKem-AJ5IdNXYMjlW3cDqbXYooKum6aIAfRkAsviWQkY7xuq3HTCICHKSPaFE9zaDUoI93bMr28R9nUjx0qchzWs1Yd2ZKwEsEIxuIdz5cZFTSrANGpPUPKo7ysmPZSjYxccVkLZ_OZi-3kZweKlKkZqOA8ZARFdB1U6vsLCu3TxmfaG4sViBT7a_I3XxamT3ym9ASeNPGXt-uYUPoRRdV1QpRH5ae_QTYVmAOtsgKtaZ5EkvTwFfRCYYh_WSyXoiMPP179w"

	tokenParts := strings.Split(token, ".")
	if len(tokenParts) != 3 {
		fmt.Println("Token JWT inválido")
		return
	}

	payloadBytes, err := base64.RawStdEncoding.DecodeString(tokenParts[1])
	if err != nil {
		fmt.Println("Erro ao decodificar o payload:", err)
		return
	}

	var cognitoToken CognitoToken
	err = json.Unmarshal(payloadBytes, &cognitoToken)
	if err != nil {
		fmt.Println("Erro ao analisar o payload JSON:", err)
		return
	}

	sess := createSession()
	client := verifiedpermissions.New(sess)

	isAuthorizedToRead(token, client)
	isAuthorizedToCreateWhenSubIsEqual(token, client)
	isAuthorizedToUpdateWhenSubIsEqual(token, client, cognitoToken.Sub)
}

func isAuthorizedToRead(token string, client *verifiedpermissions.VerifiedPermissions) bool {
	entityIdentifier := NewEntityIdentifier("ApolloApp::Ticker", "read")
	actionIdentifier := NewActionIdentifier("ApolloApp::Action", "readTicker")

	input := &verifiedpermissions.IsAuthorizedWithTokenInput{
		IdentityToken: &token,
		PolicyStoreId: &policyStoreID,
		Action:        actionIdentifier,
		Resource:      entityIdentifier,
	}

	_, err := client.IsAuthorizedWithToken(input)
	if err != nil {
		fmt.Println("Error:", err)
		return false
	}

	return true
}

func isAuthorizedToCreateWhenSubIsEqual(token string, client *verifiedpermissions.VerifiedPermissions) bool {
	entityIdentifier := NewEntityIdentifier("ApolloApp::Ticker", "createTicker")
	actionIdentifier := NewActionIdentifier("ApolloApp::Action", "createTicker")

	input := &verifiedpermissions.IsAuthorizedWithTokenInput{
		IdentityToken: &token,
		PolicyStoreId: &policyStoreID,
		Action:        actionIdentifier,
		Resource:      entityIdentifier,
	}

	_, err := client.IsAuthorizedWithToken(input)
	if err != nil {
		fmt.Println("Error:", err)
		return false
	}

	return true
}

func isAuthorizedToUpdateWhenSubIsEqual(token string, client *verifiedpermissions.VerifiedPermissions, sub string) bool {
	entityIdentifier := NewEntityIdentifier("ApolloApp::Ticker", "idDoProduto")
	actionIdentifier := NewActionIdentifier("ApolloApp::Action", "updateTicker")

	entityItem := &verifiedpermissions.EntityItem{
		Identifier: entityIdentifier,
		Attributes: map[string]*verifiedpermissions.AttributeValue{
			"user": {
				Record: map[string]*verifiedpermissions.AttributeValue{
					"sub": {
						String_: stringRef(sub),
					},
				},
			},
		},
	}

	entitiesDefinition := &verifiedpermissions.EntitiesDefinition{
		EntityList: []*verifiedpermissions.EntityItem{entityItem},
	}

	input := &verifiedpermissions.IsAuthorizedWithTokenInput{
		IdentityToken: &token,
		PolicyStoreId: &policyStoreID,
		Action:        actionIdentifier,
		Resource:      entityIdentifier,
		Entities:      entitiesDefinition,
	}

	_, err := client.IsAuthorizedWithToken(input)
	if err != nil {
		fmt.Println("Error:", err)
		return false
	}

	return true
}

/* sess := session.Must(session.NewSessionWithOptions(session.Options{
	SharedConfigState: session.SharedConfigEnable,
}))

// Criar um cliente Cognito Identity Provider
cognitoClient := cognitoidentityprovider.New(sess, aws.NewConfig().WithRegion("us-east-1")) // Substitua pela sua região

// Nome de usuário do usuário do qual você deseja obter os atributos
username := ""

input := &cognitoidentityprovider.AdminGetUserInput{
	UserPoolId: aws.String("us-east-1_Ogy4Yaluf"),
	Username:   aws.String(username),
}

output, err := cognitoClient.AdminGetUser(input)
if err != nil {
	log.Fatal("Erro ao obter os detalhes do usuário:", err)
}

for _, attr := range output.UserAttributes {
	fmt.Printf("Atributo personalizado encontrado: %s\n", aws.StringValue(attr.Value))
} */

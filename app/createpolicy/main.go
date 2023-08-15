package main

import (
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
	sess := createSession()
	client := verifiedpermissions.New(sess)
}

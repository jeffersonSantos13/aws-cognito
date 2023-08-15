permit (
    principal,
    action in [ApolloApp::Action::"updateTicker"],
    resource
) when {
    principal.sub == resource.user.sub
};

permit (
    principal,
    action in [ApolloApp::Action::"readTicker"],
    resource
)
when { 
    resource in ApolloApp::Ticker::"read"
};

permit (
    principal,
    action in [ApolloApp::Action::"createTicker"],
    resource
) when {
    principal.sub == "20ti6r3e79hvbjahpbme"
};
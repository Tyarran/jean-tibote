type envType

@bs.val external env: envType = "process.env"
@bs.get_index external getEnv: (envType, string) => string = ""

/* iLucca API */
let iluccaAPIKey = getEnv(env, "ILUCCA_API_KEY")
let iluccaAPIBaseUrl = getEnv(env, "ILUCCA_API_BASE_URL")

/* Slack API */
let slackToken = getEnv(env, "SLACK_TOKEN")
let slackChannel = getEnv(env, "SLACK_CHANNEL")
let slackVerificationToken = getEnv(env, "SLACK_VERIFICATION_TOKEN")

// App
let appPort = getEnv(env, "APP_PORT") |> int_of_string

//NewsAPI
let newsAPIToken = getEnv(env, "NEWSAPI_TOKEN")

config = exports

# Only do open tickets for now, which are tickets where support staff
# replied, but not the customer
config.state = "open"

# number of hours in the past within a ticket must be created at
# in order to be considered
config.hoursAgo = 1

body = "User details:\n\n"
body += "Plan: {plan_name}\n\n"
body += "Account: https://transloadit.com/admin/accounts/{account_email}"

config.formData =
  authorName  : "Tim Koschützki"
  authorEmail : "tim.koschuetzki@transloadit.com"
  body        : body
  internal    : true
  skip_spam   : true

config.tender =
  siteName : process.env.TENDER_SITENAME
  apiKey   : process.env.TENDER_APIKEY
  project  : process.env.TENDER_PROJECT

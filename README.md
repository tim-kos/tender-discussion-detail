Tender Discussion Detail
============================

Adds a private comment to new Tender discussion with your own custom user data.
This allows you to connect your Tender discussion authors to your own private database
with data about them, such as their Subscription plan, recent usage, etc.

More predefined data placeholders will come soon, such as recent other tickets by the author.


# Installation

`npm install --save tender-discussiondetail`

or

* Clone or fork this repo
* Run `npm install .`

# Execution

1. Supply your credentials through environment variables. Just copy **env.default.sh** into an **env.sh** file, fill out all the credentials there.

2. Copy lib/config.sample.js into lib/config.js and set the placeholders for your data properly in
config.formData.body. Adjust other settings as you see fit.

3. Write a small executable script where you use the provided discussion_analyzer module and supply your own function to fetch data based on a user email. An example would be:

```
#!/usr/bin/env node

var coffee             = require('coffee-script/register');
var DiscussionAnalyzer = require('path/to/node_module/lib/discussion_analyzer');

var fn = function(email, cb) {
  var result = null;

  // If result is null, no comment will be added

  // Some database fetching logic here
  result = {
    plan_name: 'foo plan',
    account_email: 'jim@transloadit.com'
  };
  cb(null, result);
};

var analyzer = new DiscussionAnalyzer();
analyzer.start(fn, function(err) {
  if (err) {
    throw err;
  }

  console.log('All done!');
});
```

4. Source the environment and run your custom binary script from step 3.


# TODO

- [] Write some tests

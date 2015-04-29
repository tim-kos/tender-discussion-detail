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

2. Supply a custom function to fetch data based on a user email in `./bin/tender_discussiondetail`.
See the example there.

3. Adjust your config settings in lib/config.js. SeeSet the placeholders for your data properly in
config.formData.body.

4. Run:

```
source env.sh && ./bin/tender_discussiondetail
```


# TODO

- [] Write some tests

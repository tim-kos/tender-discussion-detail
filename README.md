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

1. Write a small executable script where you use the provided discussion_analyzer module and supply your own function and config to fetch data based on a user email. An example can be found in ./bin_sample

2. Run your own custom script.


# Upgrading

If you upgrade to a new version of the plugin, make sure to back up your config.js first, as NPM will remove it.


# TODO

- [] Write some tests

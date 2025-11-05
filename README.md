# What

The *slimmer* open source error catcher that's Airbrake API compliant

# Motivation

I wanted to use, maintain and improve Errbit, but I found the code hard to maintain. So instead of starting completely from scratch, I decided to fork Errbit and make it easier to maintain.

# What's different?

In general, FAR fewer features.

- No notification service integrations
- Login with email and password only
- No issue tracker integrations
- Simpler data model
- No backwards compatibility with older Airbrake API versions (including Hoptoad)
- No RSS or iCal support
- English only
- No watchers
- Modern Rubocop w/ stricter rules

# Should you use this?

Maybe. If all you need is error reporting, it's fantastic.

## Pros

- Faster
- Easier setup
- Less code
- Easy to make changes or add features
- Feature: Automatically merge duplicate errors with different names
- Feature: Stays under MongoDB.com's free tier by discarding older instnaces of errors

## Cons

- Missing features

# What's next?

- Continue to delete code
- Continue to delete gems
- Continue to update gems
- Switch from HAML to plain ERB
- Upgrade to Rails 8
- Upgrade to Ruby 3.4
- Upgrade to ES2025
- I might switch to Postgres

# Who

This is a fork of [Errbit](https://github.com/airbrake/errbit). Shout out to the original authors!

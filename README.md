# Mail::SendgridWebApiDelivery

An extension for mail gem which sends via SendGrid API version 3

## Getting Started

### Prerequisites

You need to use ruby 2.x and have an account on SendGrid.

### Installing

Add the following line in your `Gemfile`.

```ruby
gem 'mail_sendgrid_web_api_delivery'
```

And run `bundle install`.

Then, set you SendGrid API key in environment variable with key `MAIL_SENDGRID_API_KEY`.

## Running the tests

```sh
$ bundle exec rspec spec
```

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* **MIZUNO Hiroki** - *Initial work*
* **@eitoball** - *Initial work*

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details

## Acknowledgments

* This project is build during develepment of [Misoca](https://app.misoca.jp).
* This project is supported by [Misoca, Inc.](https://info.misoca.jp/).

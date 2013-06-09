# JsonPointer [![Build Status](https://travis-ci.org/tent/json-pointer-ruby.png)](https://travis-ci.org/tent/json-pointer-ruby)

[JSON Pointer](http://tools.ietf.org/html/draft-ietf-appsawg-json-pointer-09) implementation.

## Installation

Add this line to your application's Gemfile:

    gem 'json-pointer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install json-pointer

## Usage

```ruby
hash = { :foo => { :bar => [{ :baz => "foobar" }, { :hello => "world" }, { :baz => "water" }] } }

## Simple pointer

pointer = JsonPointer.new(hash, "/foo/bar", :symbolize_keys => true)
pointer.exists? # => true
pointer.value # => [{ :baz => "foobar" }, { :hello => "world" }, { :baz => "water" }]

pointer = JsonPointer.new(hash, "/baz/bar/foo", :symbolize_keys => true)
pointer.exists? # => false
pointer.value = "Hello World!"
hash[:baz] # => { :bar => { :foo => "Hello World" } }

pointer = JsonPointer.new(hash, "/biz", :symbolize_keys => true)
pointer.exists? # => false
pointer.value # => nil

## Simple pointer with Array index

pointer = JsonPointer.new(hash, "/foo/bar/0/baz", :symbolize_keys => true)
pointer.value # => "foobar"

## Insert member into array specific index

pointer = JsonPointer.new(hash, "/foo/bar/1", :symbolize_keys => true)
pointer.value = { :baz => "foo" }
hash[:foo][:bar] # => [{ :baz => "foobar" }, { :baz => "foo" }, { :hello => "world" }, { :baz => "water" }]

## Append member to array

pointer = JsonPointer.new(hash, "/foo/bar/-", :symbolize_keys => true)
pointer.value = { :baz => "bar" }
hash[:foo][:bar] # => [{ :baz => "foobar" }, { :baz => "foo" }, { :hello => "world" }, { :baz => "water" }, { :baz => "bar" }]

## Delete array member

pointer = JsonPointer.new(hash, "/foo/bar/1", :symbolize_keys => true)
pointer.delete
hash[:foo][:bar] # => [{ :baz => "foobar" }, { :hello => "world" }, { :baz => "water" }, { :baz => "bar" }]
pointer.delete
hash[:foo][:bar] # => [{ :baz => "foobar" }, { :baz => "water" }, { :baz => "bar" }]

## Array index Wildcard

**NOTE:** `~` is specified to append to an array, this implementation also uses it to match any member of an array.

pointer = JsonPointer.new(hash, "/foo/bar/~/baz", :symbolize_keys => true)
pointer.exists? # => true
pointer.value # => ["foobar", "water", "bar"]

pointer = JsonPointer.new(hash, "/foo/bar/~/fire", :symbolize_keys => true)
pointer.exists? # => false
pointer.value = "dirt"
pointer.exists? # => true
pointer.value # => [nil, nil, nil, "dirt"]
hash[:foo][:bar] # => [{ :baz => "foobar" }, { :baz => "water" }, { :baz => "bar" }, { :fire => "dirt" }]
```

### Options

name | description
---- | -----------
symbolize_keys | Set to `true` if the hash uses symbols for keys. Default is `false`.

## TODO

- Fix nested array wildcards
- Add more test vectors
- Refactor

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

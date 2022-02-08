# `ansible-vm-build`

My `vagrant` boxes for `ansible` role development.

The boxes are available at
[https://app.vagrantup.com/trombik](https://app.vagrantup.com/trombik).


## Requirements

* `vagrant`
* `packer`
* `virtualbox`
* `ruby`

## Setting up

```console
bundle install
```

## Usage

```console
bundle exec rake -C FreeBSD-13.0
bundle exec rake -C FreeBSD-13.0 clean
```

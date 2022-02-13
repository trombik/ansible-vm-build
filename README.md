# `ansible-vm-build`

My `vagrant` boxes for `ansible` role development.

The boxes are available at
[https://app.vagrantup.com/trombik](https://app.vagrantup.com/trombik).


## Requirements

* `ruby`
* `vagrant`
* `packer`
* `virtualbox`

## Setting up

```console
bundle install
```

## Usage

See the output of `rake -T` in each directory for the summary.

Building a FreeBSD 13.0 box:


```console
bundle exec rake -C FreeBSD-13.0
```

The box file name is `virtualbox.box`.

Testing the box you have built:

```console
bundle exec rake -C FreeBSD-13.0 up test
```

Cleaning up:

```console
bundle exec rake -C FreeBSD-13.0 clean
```

`clean` target does not delete the box file.

Publishing the box:

```console
bundle exec rake -C FreeBSD-13.0 publish
```

All in one command:

```console
bundle exec rake -C FreeBSD-13.0 built up test publish
```

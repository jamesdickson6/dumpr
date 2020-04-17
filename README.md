## Dumpr
A Ruby Gem that's objective is to make dumping and importing databases easy.

Features:
* generates gzipped sql dump files for a specific database or specific tables.
* automates transfer of dump files to remote hosts
* automates import
* support for MySQL and Postgres.

Executables installed:
* dumpr
* dumpr-import

The current version is [dumpr 1.4](https://rubygems.org/gems/dumpr).

Recent changes are documented in (History)[https://github.com/jamesdickson6/dumpr/blob/master/History.md].

### Dependencies
* [Ruby &#8805; 2.2.1](http://www.ruby-lang.org/en/downloads/)

**SSH access is assumed to be automated with .ssh/config entries**

### Installation

```sh
  gem install dumpr
```
### Usage

Use the `dumpr` executable to export and import your databases.

#### dumpr

The *dumpr* command can be used to export and import database dumps.

*Exporting*

Generate yourdb.sql.gz and transfer it to server2

```sh
  dumpr --user user --password pw --db yourdb --file yourdb.sql --destination dbserver2:/data/dumps/
```

*Importing*

Then, over on dbserver2, import your dump file
```sh
  dumpr-import --user user --password pw --file /data/dumps/yourdb.sql
```

## Ruby API

You can write your own scripts that use a *Dumpr::Driver*

### Exporting

Generate yourdb.sql.gz and transfer it to another server.

```ruby
 Dumpr::Driver::Mysql.dump( 
    :user => 'backupuser', 
    :password => '12345',
    :db => 'test_database', 
    :destination => 'server2:/data/dumps/test_database.sql'
 )
```

### Importing

Then, over on **dbserver2**, import your dump file.
```ruby
 Dumpr::Driver::Mysql.import( 
    :user => 'importuser', 
    :password => '12345',
    :db => 'test_database', 
    :file => '/data/dumps/test_database.sql'
)
```

### Standard Dumpr::Driver options

See *Dumpr::Driver*
  

## TODO

* automate importing after an export (socket communication exporter/importer, or just lockfile checking / polling)
* security: stop logging passwords
* daemonize, maybe?
* SSH parameters

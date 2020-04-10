## Dumpr
A Ruby Gem that's objective is to make dumping and importing databases easy.

Features:
* generates gzipped sql dump files for a specific database or specific tables.
* automates transfer of dump files to remote hosts
* automates import

Executables installed:
* dumpr

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

Generate yourdb.sql.gz and transfer it to server2
```ruby
 Dumpr::Driver::Mysql.export( 
    :user => 'backupuser', :pass => 'dbpass',
    :db => 'yourdb', 
    :destination => 'server2:/data/dumps/yourdb.sql'
 )
```

### Importing

Then, over on dbserver2, import your dump file
```ruby
 Dumpr::Driver::Mysql.import( 
    :user => 'importuser', :pass => 'pass',
    :db => 'yourdb', 
    :file => '/data/dumps/yourdb.sql'
)
```

### Standard Dumpr::Driver options

See *Dumpr::Driver*
  
  
## CHANGELOG

### Version 1.3
* Split binary, new command `dumpr-import` to replace `dumpr --import`
* Postgres support (beta)

### Version 1.2
* Changed gem and binary command from `dumper` to `dumpr`

### Version 1.1
* Tweaks

### Version 1.0
* Initial release

## TODO
* automate importing after an export (socket communication exporter/importer, or just lockfile checking / polling)
* security: stop logging passwords
* daemonize, maybe?
* SSH parameters

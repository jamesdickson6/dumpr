## Dumper
A Ruby Gem that's objective is to make dumping and importing databases easy.

Features:
* generates gzipped sql dump files for a specific database or specific tables.
* automates transfer of dump files to remote hosts
* automates import

Executables installed:
* dumper-import
* dumper-export

TODO:
* Easily support dump all databases
* Dumper::Postgres ?
* automate importing after an export (socket communication exporter/importer, or just some dumb lockfile checking / polling)
* security: stop logging passwords
* daemonize 

### Dependencies
* [Ruby &#8805; 1.8.7](http://www.ruby-lang.org/en/downloads/)


'All SSH access is assumed to be automated with .ssh/config entries'
TODO: ssh parameters for Dumper

### Installation
```sh
  git clone https://github.com/sixjameses/dumper.git
  cd dumper
  gem install dumper0.1.gem
```
### Usage

#### dumper

The *dumper* command can be used to export and import database dumps.

*Exporting*

Generate yourdb.sql.gz and transfer it to server2

```sh
  dumper --user user --password pw --db yourdb --dumpfile yourdb.sql --destination dbserver2:/data/dumps/
```

*Importing*

Then, over on dbserver2, import your dump file
```sh
  dumper -i --user user --password pw --dumpfile /data/dumps/yourdb.sql
```

## Ruby API

You can write your own scripts that use a *Dumper::Driver*

### Exporting

Generate yourdb.sql.gz and transfer it to server2
```ruby
 Dumper::Driver::Mysql.export( 
    :user => 'backupuser', :pass => 'dbpass',
    :db => 'yourdb', 
    :destination => 'server2:/data/dumps/yourdb.sql'
 )
```

### Importing

Then, over on dbserver2, import your dump file
```rb
 Dumper::Driver::Mysql.import( 
    :user => 'importuser', :pass => 'pass',
    :db => 'yourdb', 
    :dumpfile => '/data/dumps/yourdb.sql'
)
```

### Standard Dumper::Driver options

See *Dumper::Driver*
  
  
## CHANGELOG

* Version 0.1

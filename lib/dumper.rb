require 'dumper/version'
require 'dumper/driver'

module Dumper

  # error raised when there is a bad configuration
  class BadConfig < RuntimeError; end

  # error raised when a dump filename already exists
  class DumpFileExists < RuntimeError; end

  # error raised when there is a dump operation in progress
  class BusyDumping < RuntimeError; end

  # error raised when there is a command failure
  class CommandFailure < RuntimeError; end

  def dump(driver, opts)
    driver = Driver.find(driver).new(opts)
    driver.dump()
  end

  def import(driver, opts)
    driver = Driver.find(driver).new(opts)
    driver.import()
  end

  def export(driver, opts)
    dump(driver, opts)
  end

  module_function :dump, :import, :export

end

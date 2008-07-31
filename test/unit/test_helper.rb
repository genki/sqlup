require 'rubygems'
require 'test/unit' unless defined? $ZENTEST and $ZENTEST
require 'mocha'
require 'pp'
require 'pathname'

$LIB_DIR = (Pathname.new(__FILE__).dirname + "../../lib").cleanpath.to_s
$:.unshift $LIB_DIR
require $LIB_DIR + "/sqlup"
require 'mysql_backup/entity/identifier'

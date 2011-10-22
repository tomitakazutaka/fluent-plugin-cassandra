module Fluent


class CassandraOutput < BufferedOutput
  Fluent::Plugin.register_output('cassandra', self)
  include SetTimeKeyMixin
  include SetTagKeyMixin
  config_set_default :include_time_key, true
  config_set_default :include_tag_key, true
  config_set_default :time_format, "%Y%m%d%H%M%S"


  def initialize
    super
    require 'cassandra'
    require 'msgpack'
  end

  def configure(conf)
    super

    raise ConfigError, "'Keyspace' parameter is required on cassandra output"   unless @keyspace = conf['keyspace']
    raise ConfigError, "'ColumnFamily' parameter is required on cassandra output"   unless @columnfamily = conf['columnfamily']

    @host = conf.has_key?('host') ? conf['host'] : 'localhost'
    @port = conf.has_key?('port') ? conf['port'] : 9160
  end

  def start
    super
    @connection = Cassandra.new(@keyspace, @host + ':' + @port )
  end

  def shutdown
    super
  end

  def format(tag, time,record)
    record.to_msgpack
  end

  def write(chunk)
    chunk.msgpack_each  { |record|
            @connection.insert(
                    @columnfamily,
                    record["tag"] + "_" + record["time"].to_s,
                    record
                    )
    }
  end
end


end

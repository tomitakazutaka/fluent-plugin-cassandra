module Fluent


class CassandraOutput < BufferedOutput
  Fluent::Plugin.register_output('cassandra', self)

  def initialize
    super
    require 'cassandra'
    require 'msgpack'
  end

  def configure(conf)
    super

    raise ConfigError, "'Keyspace' parameter is required on file output"   unless @keyspace = conf['keyspace']
    raise ConfigError, "'ColumnFamily' parameter is required on file output"   unless @columnfamily = conf['columnfamily']

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

  def format(tag, event)
    [tag,event.time,event.record].to_msgpack
  end

  def write(chunk)
    chunk.open { |io|
      begin
        MessagePack::Unpacker.new(io).each { |record|
            c_key = record[0] + "_" + record[1].to_s
            @connection.insert(@columnfamily,c_key,record[2])
        }
      rescue EOFError
        # EOFError always occured when reached end of chunk.
      end
    }
  end
end


end

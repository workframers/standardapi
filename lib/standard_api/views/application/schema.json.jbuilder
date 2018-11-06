mapping = lambda do |sql_type|
  case sql_type
  when /character varying(\(\d+\))?/
    'string'
  when 'timestamp without time zone'
    'datetime'
  when 'time without time zone'
    'datetime'
  when 'text'
    'string'
  when 'json'
    'hash'
  when 'bigint'
    'integer'
  when 'integer'
    'integer'
  when 'jsonb'
    'hash'
  when 'inet'
    'string' # TODO: should be inet
  when 'hstore'
    'hash'
  when 'date'
    'datetime'
  when 'numeric(162)'
    'decimal'
  when 'numeric'
    'decimal'
  when 'double precision'
    'decimal'
  when 'ltree'
   'string'
  when 'boolean'
    'boolean'
  when 'geometry'
    'ewkb'
  when 'uuid' # TODO: should be uuid
    'string'
  end
end

json.set! 'columns' do
  model.columns.each do |column|
    json.set! column.name, {
      type: mapping.call(column.sql_type),
      primary_key: column.name == model.primary_key,
      null: column.null,
      array: column.array
    }
  end
end

json.set! 'limit', resource_limit

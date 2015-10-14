module StandardAPI
  module Helpers

    def model_partial(record)
      if lookup_context.exists?(record.model_name.element, record.model_name.plural, true)
        [record.model_name.plural, record.model_name.element].join('/')
      else
        'application/record'
      end
    end
    
    def can_cache?(model, relation, subincludes)
      cache_columns = cached_at_columns_for_includes(relation, subincludes)
      if (cache_columns - model.attribute_names).empty?
        !cache_columns.any? { |cc| model.send(cc).nil? }
      else
        false
      end
    end
    
    def association_cache_key(record, relation, subincludes)
      timestamp = cached_at_columns_for_includes(relation, subincludes)
      timestamp.map! { |col| record.send(col) }
      timestamp = timestamp.max
      
      case association = record.class.reflect_on_association(relation)
      when ActiveRecord::Reflection::HasManyReflection, ActiveRecord::Reflection::HasAndBelongsToManyReflection, ActiveRecord::Reflection::HasOneReflection
        "#{record.model_name.cache_key}/#{record.id}/#{includes_to_cache_key(relation, subincludes)}-#{timestamp.utc.to_s(record.cache_timestamp_format)}"
      when ActiveRecord::Reflection::BelongsToReflection
        if subincludes.empty?
          "#{association.klass.model_name.cache_key}/#{record.send(association.foreign_key)}-#{timestamp.utc.to_s(association.klass.cache_timestamp_format)}"
        else
          "#{association.klass.model_name.cache_key}/#{record.send(association.foreign_key)}/#{digest_hash(sort_hash(subincludes))}-#{timestamp.utc.to_s(association.klass.cache_timestamp_format)}"
        end

      else
        raise ArgumentError, 'Unkown association type'
      end
    end
    
    def cached_at_columns_for_includes(relation, subincludes)
      if subincludes.empty?
        ["#{relation}_cached_at"]
      else
        subincludes.select{|k,v| ![:where, :limit, :order].include?(k.to_sym) }.map { |k, v|
          cached_at_columns_for_includes(k, v)
        }.flatten.map { |k|
          "#{relation}_#{k}"
        } + ["#{relation}_cached_at"]
      end
    end
    
    def includes_to_cache_key(relation, subincludes)
      if subincludes.empty?
        relation.to_s
      else
        "#{relation}-#{digest_hash(sort_hash(subincludes))}"
      end
    end
    
    def sort_hash(hash)
      hash.keys.sort.reduce({}) do |seed, key|
        if seed[key].is_a?(Hash)
          seed[key] = sort_hash(hash[key])
        else
          seed[key] = hash[key]
        end
        seed
      end
    end

    def digest_hash(*hashes)
      hashes.compact!
      hashes.map! { |h| sort_hash(h) }

      digest =  Digest::MD5.new()
      hashes.each do |hash|
        hash.each do |key, value|
          digest << key.to_s
          if value.is_a?(Hash)
            digest << digest_hash(value)
          else
            digest << value.to_s
          end
        end
      end

      digest.hexdigest
    end
    

  end
end
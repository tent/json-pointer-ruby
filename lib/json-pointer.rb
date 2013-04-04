require "json-pointer/version"

class JsonPointer

  NotFound = Class.new
  WILDCARD = "*".freeze
  ARRAY_PUSH_KEY = '-'.freeze

  def initialize(hash, path, options = {})
    @hash, @path, @options = hash, path, options
  end

  def value
    get_member_value
  end

  def value=(new_value)
    set_member_value(new_value)
  end

  def delete
    delete_member
  end

  def exists?
    _exists = false
    get_target_member(@hash, path_fragments.dup) do |target|
      _exists = true unless NotFound === target
    end
    _exists
  end

  private

  def get_member_value(obj = @hash, fragments = path_fragments.dup)
    return obj if fragments.empty?

    fragment = fragments.shift
    case obj
    when Hash
      get_member_value(obj[fragment_to_key(fragment)], fragments)
    when Array
      if fragment == WILDCARD
        obj.map { |i| get_member_value(i, fragments.dup) }
      else
        get_member_value(obj[fragment_to_index(fragment)], fragments)
      end
    end
  end

  def get_target_member(obj, fragments, options = {}, &block)
    return yield(obj) if fragments.empty?

    fragment = fragments.shift
    case obj
    when Hash
      key = fragment_to_key(fragment)
      obj = if options[:create_missing]
        obj[key] ||= Hash.new
      else
        obj.has_key?(key) ? obj[key] : NotFound.new
      end

      get_target_member(obj, fragments, options, &block)
    when Array
      if fragment == WILDCARD
        obj.each do |i|
          get_target_member(i || Hash.new, fragments.dup, options, &block)
        end
      else
        index = fragment_to_index(fragment)
        obj = if options[:create_missing]
          obj[index] ||= Hash.new
        else
          index >= obj.size ? NotFound.new : obj[index]
        end

        get_target_member(obj, fragments, &block)
      end
    else
      NotFound.new
    end
  end

  def set_member_value(new_value)
    obj = @hash
    fragments = path_fragments.dup

    return if fragments.empty?

    target_fragment = fragments.pop

    if target_fragment == ARRAY_PUSH_KEY
      target_parent_fragment = fragments.pop
    end

    get_target_member(obj, fragments, :create_missing => true) do |target|
      if target_fragment == ARRAY_PUSH_KEY
        case target
        when Hash
          key = fragment_to_key(target_parent_fragment)
        when Array
          key = fragment_to_index(target_parent_fragment)
        end

        target[key] ||= Array.new
        if Array === target[key]
          target[key].push(new_value)
          return new_value
        else
          return
        end
      end

      case target
      when Hash
        target[fragment_to_key(target_fragment)] = new_value
      when Array
        if target_fragment == WILDCARD
          target.map! { new_value }
        else
          target.insert(fragment_to_index(target_fragment), new_value)
        end
      end
    end
  end

  def delete_member
    obj = @hash
    fragments = path_fragments.dup

    return if fragments.empty?

    target_fragment = fragments.pop
    get_target_member(obj, fragments) do |target|
      case target
      when Hash
        target.delete(fragment_to_key(target_fragment))
      when Array
        if target_fragment == WILDCARD
          target.replace([])
        else
          target.delete_at(fragment_to_index(target_fragment))
        end
      end
    end
  end

  def path_fragments
    @path_fragments ||= @path.sub(%r{\A/}, '').split("/").map { |fragment| unescape_fragment(fragment) }
  end

  def unescape_fragment(fragment)
    fragment.gsub(/~1/, '/').gsub(/~0/, '~')
  end

  def fragment_to_key(fragment)
    if @options[:symbolize_keys]
      fragment.to_sym
    else
      fragment
    end
  end

  def fragment_to_index(fragment)
    fragment.to_i
  end

end

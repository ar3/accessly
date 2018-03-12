module AccessControl

  # Permission checks directly related to specific ActiveRecord records happen here.
  class PermittedActionOnObjectQuery

    def initialize(actor)
      @actor = actor
    end

    # Ask whether the actor has permission to perform action_id
    # on a given record.
    #
    # @param action_id [Integer, Array<Integer>] The action or actions we're checking whether the actor has. If this is an array, then the check is ORed.
    # @param object_type [ActiveRecord::Base] The ActiveRecord model which we're checking for permission on.
    # @param object_id [Integer] The id of the ActiveRecord object which we're checking for permission on.
    # @return [Boolean] Returns true if actor has been granted the permission on the specified record, false otherwise.
    #
    # @example
    #   # Can the user perform the action with id 5 for the Post with id 7?
    #   AccessControl::Records.can?(user, 5, Post, 7)
    def can?(action_id, object_type, object_id)
      find_or_set_value(:can, @actor.class.name, @actor.id, action_id, object_type) do
        PermittedActionOnObject.where(
          actor: @actor,
          action: action_id,
          object_type: String(object_type),
          object_id: object_id
        ).exists?
      end
    end

    def list(action_id, object_type)
    end

    private

    def past_lookups
      @_past_lookups ||= {}
    end

    def find_or_set_value(*keys, &query)
      found_value = past_lookups.dig(*keys)
      found_value = found_value.nil? ? query.call : found_value
      set_value(*keys, value: found_value)

      found_value
    end

    def set_value(*keys, value:)
      lookup = past_lookups
      keys[0..-2].each do |key|
        lookup[key] ||= {}
        lookup = lookup[key]
      end

      lookup[keys[-1]] = value
    end
  end
end
class Service::Jira < Service::Adapter
  class Payload < Struct.new(:payload)
    REGEXP = /\[#(.+)\]/.freeze

    attr_reader :issue_id, :actions

    def initialize(payload)
      super
      keywords = REGEXP.match(payload['message'])
      if keywords
        splits = keywords[1].split
        initialize_issue_id(splits)
        initialize_actions(splits)
      end
    end

    def any?
      issue_id && transition
    end

    def transition
      actions['transition']
    end

    def to_json
      body.to_json
    end

    def body
      { :transition => { :id => transition } }
    end

    private

    def initialize_issue_id(splits)
      @issue_id = splits.shift
    end

    def initialize_actions(splits)
      @actions = splits.each_with_object({}) { |action, hash|
        hash.update(Hash[[action.split(':')]])
      }
    end
  end
end

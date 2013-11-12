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

    def to_json
      body.to_json
    end

    def body
      with_hash do |hash|
        hash[:transition] = transition
        hash[:fields].update(:resolution => resolution) if resolution
        hash[:update].update(:comment => [{ :add => { :body => comment } }])
      end
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

    def transition
      id_or_name(actions['transition'] || actions['status'])
    end

    def resolution
      id_or_name(actions['resolution'])
    end

    def comment
      "#{message}\n\nvia #{commit_url}"
    end

    def message
      payload['message']
    end

    def commit_url
      payload['url']
    end

    def id_or_name(input)
      return unless input

      if input =~ /\d+/
        { :id => input }
      else
        { :name => input.inspect }
      end
    end

    def with_hash
      hash = { :fields => {}, :update => {} }
      yield(hash)
      hash
    end

  end

end

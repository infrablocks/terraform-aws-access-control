# frozen_string_literal: true

require 'iostreams'

module IOStreams
  module Pgp
    # Overrides the default implementation so that --no-tty can be passed to
    # the command.
    #
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    def self.import(key:)
      version_check
      command = "#{executable} --no-tty --batch --import"

      out, err, status = Open3.capture3(command, binmode: true, stdin_data: key)
      logger&.debug { "IOStreams::Pgp.import: #{command}\n#{err}#{out}" }
      if status.success? && !err.empty?
        # Sample output
        #
        #   gpg: key C16500E3: secret key imported
        #   gpg: key C16500E3: public key "Joe Bloggs <pgp_test@iostreams.net>"
        #     imported
        #   gpg: Total number processed: 1
        #   gpg:               imported: 1  (RSA: 1)
        #   gpg:       secret keys read: 1
        #   gpg:   secret keys imported: 1
        #
        # Ignores unchanged:
        #   gpg: key 9615D46D: \"Joe Bloggs <j@bloggs.net>\" not changed\n
        results = []
        secret  = false
        err.each_line do |line|
          if line =~ /secret key imported/
            secret = true
          elsif (match = line.match(/key\s+(\w+):\s+(\w+).+"(.*)<(.*)>"/))
            results << {
              key_id: match[1].to_s.strip,
              private: secret,
              name: match[3].to_s.strip,
              email: match[4].to_s.strip
            }
            secret = false
          end
        end
        results
      else
        return [] if err =~ /already in secret keyring/

        raise(Pgp::Failure, "GPG Failed importing key: #{err}#{out}")
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
  end
end

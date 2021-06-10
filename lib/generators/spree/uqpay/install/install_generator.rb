require "rails/generators"
require "rails/generators/migration"
require "rails/generators/active_record"

module Spree
  module Uqpay
    module Generators
      class InstallGenerator < Rails::Generators::Base
        include Rails::Generators::Migration

        class_option :auto_run_migrations, type: :boolean, default: false

        source_root File.expand_path("templates", __dir__)

        def self.next_migration_number(path)
          ActiveRecord::Generators::Base.next_migration_number(path)
        end

        def create_migrations
          migration_template "migration.rb", "db/migrate/create_spree_uqpay_payment_sources.rb", migration_version: migration_version
        end

        def create_initializers
          template "check_payment_status_worker.rb", "app/workers/check_payment_status_worker.rb"
          template "schedule.yml", "config/schedule.yml"
        end

        def add_migrations
          run 'bundle exec rake railties:install:migrations'
        end

        def run_migrations
          run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask('Would you like to run the migrations now? [Y/n]'))
          if run_migrations
            run 'bundle exec rake db:migrate'
          else
            puts 'Skipping rake db:migrate, don\'t forget to run it!'
          end
        end

        private
  
        def migration_version
          "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]" if ActiveRecord.version.version > "5"
        end
      end
    end
  end
end
  
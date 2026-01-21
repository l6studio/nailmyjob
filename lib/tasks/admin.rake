# frozen_string_literal: true

namespace :admin do
  desc "Make a user an admin by email"
  task :promote, [:email] => :environment do |_t, args|
    email = args[:email]

    if email.blank?
      puts "Usage: bin/rails admin:promote[email@example.com]"
      exit 1
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "User not found: #{email}"
      exit 1
    end

    if user.admin?
      puts "#{email} is already an admin"
    else
      user.update!(role: :admin)
      puts "#{email} is now an admin"
    end
  end

  desc "List all admin users"
  task list: :environment do
    admins = User.where(role: :admin)

    if admins.empty?
      puts "No admin users found"
    else
      puts "Admin users:"
      admins.each do |user|
        puts "  - #{user.email} (#{user.full_name})"
      end
    end
  end
end

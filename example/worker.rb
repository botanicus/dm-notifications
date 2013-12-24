# encoding: utf-8

require_relative "models.rb"

User.all(include: "friendships").each do |user|
  user.notifications_queue.subscribe do |data|
    attributes = JSON.parse(data)
    Notification.create(attributes)
  end
end

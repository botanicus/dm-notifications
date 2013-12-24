# encoding: utf-8

require "mq"

module NotificationsMixin
  def self.included(base)
    unless base.instance_method_defined?(:name)
      raise RuntimeError.new("#{base} has to respond to #name method!")
    end
  end

  # followers fanout
  def create_followers_fanout
    self.followers_fanout(no_declare: false)
  end

  def followers_fanout(options = nil)
    @followers_fanout_options ||= begin
      {durable: true, no_declare: true}
    end

    options = @followers_fanout_options.merge(options)

    @followers_fanout ||= begin
      MQ.fanout("#{self.name}_followers", options)
    end
  end

  # notifications queue
  def create_notifications_queue
    self.notifications_queue(no_declare: false)
  end

  def notifications_queue(options = nil)
    @notifications_queue_options ||= begin
      {durable: true, no_declare: true}
    end

    options = @notifications_queue_options.merge(options)

    @notifications_queue ||= begin
      MQ.queue("#{self.name}_notifications", options)
    end
  end
end

# for User
module ProducerMixin
  def publish(notification)
    data = encode_notification(notification)
    self.followers_fanout.publish(data)
  end

  # @api plugin
  # Redefine this method in order to customize what is published, so for example you might want to push just raw SQL statements and run them directly on the worker(s), so you won't need to create bunch of objects just to call #save on them.
  def encode_notification(notification)
    notification.attributes.to_json
  end
end

# class User
#
#   has (0..n), :followers,  self, through: :friendships, via: :target, notifications: true
# end

# class Friendship
#   belongs_to :source, User, notifications: true
# end
module NotificationsConsumerMixin
  include NotificationsMixin

  def self.included(base)
    base.after(:save) do
      self.create_followers_fanout
      self.create_notifications_queue
    end

    base.after(:destroy) do
      self.destroy_followers_fanout
      self.destroy_notifications_queue
    end
  end
end

class Notification
  include DataMapper::Resource
  property :message, Text
  belongs_to :user
  belongs_to :subject, model: User
end

# + bind
follower.notifications_queue.bind(user.followers_fanout)

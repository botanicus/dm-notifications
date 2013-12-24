# encoding: utf-8

# This is a great example of N:N messaging, imagine networks like Twitter where user has huge number of followers

# count of fanouts == count of queues == User.count
# subscriptions count == Friendship.count

require "mq"
require "eventmachine"
require "em-mysqlplus"

AMQP.start do
  User.all(include: "friendships").each do |user|
    user.notifications_queue.subscribe do |values|
      query = mysql.query("INSERT INTO notifications VALUES (#{values})")
      query.callback do
        # TODO: send ack
      end
    end
  end
end

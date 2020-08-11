# frozen_string_literal: true

require 'redis'

conn = Redis.new

def list_all_users(conn, index)
  conn.zrevrange(index, 0, -1)
end

def gather_roles_indexes(conn)
  dest = 'identity:roles:all'
  conn.zunionstore dest,
                   ['identity:roles:super:admin', 'identity:roles:admin:assistant',
                    'identity:roles:reviewer', 'identity:roles:app:admin',
                    'identity:roles:app:assistant', 'identity:roles:end:user'],
                   aggregate: 'min'
  conn.expire dest, 60
  dest
end

def zdiff(conn, keys)
  dest = 'identity:roles:empty'
  conn.zunionstore dest, keys, weights: [1, 0], aggregate: 'min'
  conn.zrevrangebyscore dest, '+inf', 1
end

users_index = 'identity:users'

all_users = list_all_users conn, users_index
puts "Total number of users: #{all_users.length}"

roles_index = gather_roles_indexes(conn)

with_roles = list_all_users conn, roles_index
puts "Total number of users with roles: #{with_roles.length}"

without_roles = zdiff(conn, [users_index, roles_index])
puts "Total number of users without roles: #{without_roles.length}"

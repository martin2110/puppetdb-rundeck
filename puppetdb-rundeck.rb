#!/usr/bin/env ruby
require 'rubygems'
require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'sinatra'
# set your puppetdb info
puppetdb_host = 'localhost'
puppetdb_port = '8080'

before do
  response["Content-Type"] = "application/yaml"
end

get '/' do
  uri = URI.parse( "http://#{puppetdb_host}:#{puppetdb_port}/resources" ); params = {'query'=>'["=", "type", "Class"],]'}
  http = Net::HTTP.new(uri.host, uri.port) 
  request = Net::HTTP::Get.new(uri.path) 
  request.add_field("Accept", "application/json")
  request.set_form_data( params )
  request = Net::HTTP::Get.new( uri.path+ '?' + request.body ) 
  request.add_field("Accept", "application/json")
  response = http.request(request)
  puppetdb_data = JSON.parse(response.body)

  rundeck_data = Hash.new
  puppetdb_data.each{|d|
    host     = d['certname']
    title    = d['title']
    rundeck_data[host] = Hash.new if not rundeck_data.key?(host)
    rundeck_data[host]['tags'] = Array.new if not rundeck_data[host].key?('tags')
    rundeck_data[host]['tags'] << title
  }
  rundeck_data.keys.sort.each {|k|
    rundeck_data[k]['tags'].uniq!
    rundeck_data[k]['tags'] =  rundeck_data[k]['tags'].join(",")
    rundeck_data[k]['hostname'] = k
  }
  rundeck_data.to_yaml
end

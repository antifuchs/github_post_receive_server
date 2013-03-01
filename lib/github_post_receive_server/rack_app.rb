# -*- coding: utf-8 -*-
#
#  rack_app.rb
#  github_post_commit_server
#
#  Example Rack app for http://github.com/guides/post-receive-hooks
#
#  Created by James Tucker on 2008-05-11.
#  Copyright 2008 James Tucker
#

require 'rubygems'
require 'rack'
require 'json'
require 'erb'

$stdout.sync = true  # Make logging possible

module GithubPostReceiveServer
  class RackApp
    GO_AWAY_COMMENT = "Be gone, foul creature of the internet."
    THANK_YOU_COMMENT = "Thanks! You beautiful soul you."

    # This is what you get if you make a request that isn't a POST with a
    # payload parameter.
    def rude_comment
      @res.write GO_AWAY_COMMENT
    end

    # Does what it says on the tin. By default, not much, it just prints the
    # received payload.
    def handle_request
      payload = @req.POST["payload"]

      return rude_comment if payload.nil?

      puts payload unless $DEPLOYED # remove me!

      payload = JSON.parse(payload)
#      render_payload_to_hipchat(payload)
      @res.write THANK_YOU_COMMENT
    end

    TEMPLATE_COMMIT_SINGLE = <<-HTML
<%= committer %> pushed 1 commit to <%= branch %> on <%= repo_name %>: <%= description %> (<%= url %>)
HTML

    TEMPLATE_COMMIT_MULTI = <<-HTML
<%= committer %> pushed <%= commits.length %> commits to <%= branch %> on <%= repo_name %>:<br/>
<ul>
<% commits.each do |commit| %>
  <li><%= commit[:description] %> (<%= commit[:url]%>)
<% end %>
</ul>
HTML

    class SingleCommit
      def initialize(committer, branch, repo_name, description, url)
        @committer = committer
        @branch = branch
        @repo_name = repo_name
        @description = description
        @url = url
      end
    end

    def render_payload_to_hipchat(payload)
      case payload['commits'].length
      when 1
        context = SingleCommit.new(payload['commits'][0]['author']['name'])
      else
        raise "oh noees, more than one commit"
      end
    end

    # Call is the entry point for all rack apps.
    def call(env)
      @req = Rack::Request.new(env)
      @res = Rack::Response.new
      handle_request
      @res.finish
    end
  end
end

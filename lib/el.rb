# frozen_string_literal: true
require 'pry'
require 'set'
require 'stringio'
require 'parser/current'
require 'unparser'
require 'erb'
require 'json'
require 'date'
require 'rack'
require 'singleton'
require 'forwardable'

require_relative 'el/utils'
require_relative 'el/html_helpers'

require_relative 'el/markup'
require_relative 'el/scriptable'
require_relative 'el/javascript'
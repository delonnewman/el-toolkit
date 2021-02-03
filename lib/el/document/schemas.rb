# frozen_string_literal: true
module El
  class Document
    module Schemas
      HTML5 = {
        doctype: '<!doctype html>',
        mime_type: 'text/html',
        content_elements: Set[
          :html, :body, :head, :style, :div, :p, :a, :script, :table,
          :tr, :td, :th, :strong, :li, :ul, :ol, :h1, :h2, :h3, :h4, :h5, :h6,
          :span, :nav, :main, :header, :button, :form, :code, :pre, :textarea,
          :submit, :select, :option, :thead, :tbody
        ].freeze,
        singleton_elements: Set[
          :br, :img, :link, :meta, :base, :area, :col, :hr, :input,
          :param, :source, :track, :wbr, :keygen
        ].freeze,
      }.freeze

      HTML  = HTML5
      XHTML = HTML5.merge(
        xml: true,
        doctype: '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
        mime_type: 'application/xhtml+xml'
      )

      XML = {
        xml: true,
        doctype: '<?xml version="1.0" encoding="UTF-8" ?>',
        mime_type: 'application/xml',
        content_elements: [],
        singleton_elements: [],
      }

      RSS = XML.merge(
        mime_type: 'application/rss+xml',
        content_elements: Set[:rss, :channel, :title, :description, :link, :copyright, :lastBuildDate, :pubDate, :ttl, :item, :guid],
        singleton_elements: Set.new
      )

      Atom = XML.merge(
        mime_type: 'application/atom+xml',
        content_elements: Set[:feed, :title, :subtitle, :id, :updated, :entry, :summary, :content, :author, :name, :email],
        singleton_elements: Set[:link]
      )
    end
  end
end

# frozen_string_literal: true

module El
  module Routable
    NOT_FOUND_TMPL = <<~HTML
      <!doctype html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <style>
             body {
               font-family: sans-serif
             }

             main {
               width: 80%;
               margin-right: auto;
               margin-left: auto;
             }

             table {
               font-family: sans-serif;
               border-spacing: 0;
               border-collapse: collapse;
             }

             .routes table {
               font-family: monospace;
             }

             .routes table, .routes table tr {
               border: solid 1px #e0e0e0;
             }

             .routes table td, .routes table th {
                padding: 5px 10px;
             }

             .environment {
               margin-top: 20px;
               max-width: 100vw;
             }

             .environment > h2 {
                margin-bottom: 0;
             }

             .environment table td > pre {
               max-height: 50px;
               overflow: scroll;
             }

             .environment table th {
               text-align: right;
               padding-right: 10px;
             }
          </style>
        </head>
        <body>
          <main>
           %BODY%
          </main>
        </body>
      </html>
    HTML
  end
end

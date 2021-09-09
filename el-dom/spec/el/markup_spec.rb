require 'el-dom'

RSpec.describe El::Document do
  let(:html) { described_class[:HTML] }
  let(:xhtml) { described_class[:XHTML] }

  it "should generate code according to it's doctype" do
    examples = [
      { test: ->(markup) { markup.br.to_markup },
        html: '<br>',
        xhtml: '<br/>' },
      { test: ->(markup) { markup.link(rel: 'stylesheet', href: '/styles/app.css').to_markup },
        html: "<link rel='stylesheet' href='/styles/app.css'>",
        xhtml: '<link rel="stylesheet" href="/styles/app.css"/>' },
      { test: ->(markup) { markup.a(href: '#', required: true, class: %w[btn btn-primary]).to_markup },
        html: "<a href='#' required class='btn btn-primary'></a>",
        xhtml: '<a href="#" required="required" class="btn btn-primary"></a>' }
    ]

    examples.each do |example|
      expect(example[:test].call(html)).to eq example[:html]
      expect(example[:test].call(xhtml)).to eq example[:xhtml]
    end
  end

  context '#xml?' do
    it 'should return true if the doctype is xml, false otherwise' do
      expect(html.xml?).to be false
      expect(xhtml.xml?).to be true

      expect(html.br.xml?).to be false
      expect(xhtml.br.xml?).to be true
    end
  end

  context 'document block' do
    it 'should generate markup implicitly' do
      code = El::Document[:HTML] do
        a(href: '#') { 'Testing' } + br
        br
      end.to_s

      expect(code.lines.map(&:chomp).join('')).to eq "<a href='#'>Testing</a><br><br>"
    end

    it 'should generate markup explicitly' do
      code = El::Document[:HTML] do |html|
        html.a(href: '#') { 'Testing' } + html.br
        html.br
      end.to_s

      expect(code.lines.map(&:chomp).join('')).to eq "<a href='#'>Testing</a><br><br>"
    end
  end
end

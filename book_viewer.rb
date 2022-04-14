require "sinatra"
require "sinatra/reloader" if development?

before do
  @contents = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(chapter_contents)
    chapter_contents.split("\n\n").map.with_index do |paragraph, index|
      "<p id=para#{index}>#{paragraph}</p>"
    end.join
  end
  
  def bold_search(content, search_term)
    content.gsub(search_term, "<strong>#{search_term}</strong>")
  end
end

not_found do
  redirect "/"
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  chapter_title = @contents[number - 1]
  
  redirect "/" unless (1..@contents.size).cover?(number)
  
  @title = "Chapter #{number}: #{chapter_title}"
  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end

def each_chapter
  @contents.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield number, name, contents
  end
end

def query_results(search_term)
  results = []
  return results if !search_term || search_term == ""
  each_chapter do |number, name, contents|
    if contents.match?(search_term)
      paragraphs = contents.split("\n\n")
      matched_paragraphs = []
      paragraphs.each_with_index do |paragraph, index|
        matched_paragraphs << { index => paragraph } if paragraph.match?(search_term)
      end
      results << { number: number, name: name, matched_paragraphs: matched_paragraphs }
    else
      next
    end
  end
  results
end

get "/search" do
  search_term = params[:query]
  @results = query_results(search_term)
  
  erb :search
end
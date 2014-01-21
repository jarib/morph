module CodeTranslate
  # Translate Ruby code on ScraperWiki to something that will run on Morph
  def self.translate(language, code)
    case language
    when :ruby
      Ruby::translate(code)
    when :php
      PHP::translate(code)
    when :python
      Python::translate(code)
    else
      raise "unsupported language"
    end
  end

  def self.sql(sql)
    sql.gsub('swdata', 'data')
  end

  module PHP
    def self.translate(code)
      change_table_in_select(add_require(code))
    end

    # Add require immediately after "<?php"
    def self.add_require(code)
      if code =~ /require ['"]scraperwiki.php['"]/
        code
      else      
        code.sub(/<\?php/, "<?php\nrequire 'scraperwiki.php';")
      end
    end

    def self.change_table_in_select(code)
      code.gsub(/scraperwiki::select\((['"])(.*)(['"])(.*)\)/) do |s|
        "scraperwiki::select(#{$1}#{CodeTranslate.sql($2)}#{$3}#{$4})"
      end
    end
  end

  module Python
    def self.translate(code)
      code
    end
  end    

  module Ruby
    def self.translate(code)
      add_instructions_for_libraries(change_table_in_sqliteexecute_and_select(add_require(code)))
    end

    # If necessary adds "require 'scraperwiki'" to the top of the scraper code
    def self.add_require(code)
      if code =~ /require ['"]scraperwiki['"]/
        code
      else
        code = "require 'scraperwiki'\n" + code
      end
    end

    def self.change_table_in_sqliteexecute_and_select(code)
      code.gsub(/ScraperWiki.(sqliteexecute|select)\((['"])(.*)(['"])(.*)\)/) do |s|
        "ScraperWiki.#{$1}(#{$2}#{CodeTranslate.sql($3)}#{$4}#{$5})"
      end
    end

    def self.add_instructions_for_libraries(code)
      code.gsub(/require 'scrapers\/(.*)'/) do |s|
        i = <<-EOF
# TODO:
# 1. Fork the ScraperWiki library (if you haven't already) at https://classic.scraperwiki.com/scrapers/#{$1}/
# 2. Add the forked repo as a git submodule in this repo
# 3. Change the line below to load to something like require File.dirname(__FILE) + '/#{$1}/scraper'
# 4. Remove these instructions
        EOF
        i + s
      end
    end
  end
end
# encoding: UTF-8
require 'httparty'
require 'nokogiri'
require File.join(File.dirname(__FILE__), 'stations')

module DiMLOrb
  DIMLO_URI = "http://www.dimlo.es/Informate/calc.aspx"
  class DiMLOrb
      
      attr_accessor :proximo, :siguiente, :duracion, :from, :to

      # DiMLOrb.new receives the Metro Ligero Oeste station you are going from and your desired destination
      # it returns you an object with mainly 3 attributes:
      # => proximo   = next train arrives in X minutes
      # => siguiente = the following train arrives in Y minutes
      # => duraction = how long should it take to go from one station to the other
      def initialize(from = :ColoniaJardin, to = :SomosaguasSur)
          @from, @to = STATIONS[from], STATIONS[to]
          get_validations
          get_times
      end
      
      # diMLO website uses cookies and token validations (aka protect from forgery) in its forms
      # *get_validations* grabs this values, namely: cookie, viewstate and eventvalidation
      def get_validations
          resp = HTTParty.get(DIMLO_URI)
          raise "HTTP Error: #{resp.code}" if resp.code.to_i != 200
        
          @cookie = resp.response['set-cookie'].split('; ')[0]
          doc  = Nokogiri::HTML(resp.body)
          @viewstate = doc.css('#__VIEWSTATE').attr('value').value
          @eventvalidation = doc.css('#__EVENTVALIDATION').attr('value').value
      end
    
      # *get_times* asks diMLO website for the next metro timetable and parses the html
      # to grab the values of _proximo_, _siguiente_ and _duracion_
      def get_times
          resp = HTTParty.post(DIMLO_URI, {:body => form_options, :headers => headers})
          doc  = Nokogiri::HTML(resp.body)
          @proximo = doc.css('#ProximoTXT').inner_text
          @siguiente = doc.css('#SiguienteTXT').inner_text
          @duracion = doc.css('#DuracionTXT').inner_text
      end
    
      protected
      
      # options needed in the form to get the timetables
      # also validation tokens, etc
      def form_options
          { 
              'origenDDL' => @from, 
              'destinoDDL' => @to,
              '__EVENTVALIDATION' => @eventvalidation, 
              '__VIEWSTATE'   => @viewstate,
              'btnCalcular.x' =>	'48',
              'btnCalcular.y' =>'5'
          }
      end
      
      # Mandatory HTTP headers
      def headers
          {   
              'Cookie' => @cookie, 
              'Host' =>	"www.dimlo.es",
              'User-Agent' =>	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:2.0) Gecko/20100101 Firefox/4.0",
              'Referer' =>	'http://www.dimlo.es/Informate/calc.aspx'
          }
      end
    
      # debugging function
      def to_file(file_name = 'dimlo.html')
          f = File.new(file_name,  "w+")
          f.puts @html
          `open #{file_name}`
      end
      # debugging function
      def from
        @from.split("|").first
      end
      # debugging function    
      def to
        @to.split("|").first
      end
  end
end
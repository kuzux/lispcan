require 'rubygems'
require 'rparsec'

#Sexp gem + my ownn modifications
module SExpressionParser
  extend RParsec::Parsers

  def self.stringer(opener, closer=nil, translate={})
    closer = opener if closer.nil?
    escape = (string('\\') >> any).map do |charnum|
      escaped = charnum.chr
      translate[escaped] || escaped
    end
    open   = string(opener)
    close  = string(closer)
    other  = not_string(closer).map{|charnum| charnum.chr }
    string = (open >> (escape|other).many << close).map {|strings| strings.to_s }
  end

  Integer = integer.map{|x| x.to_i }
  Float = number.map{|x| x.to_f }
  Number = longest(Integer, Float)
  Special = Regexp.escape('+-*/=<>?!@#$%^&:\\~|^.')
  Symbol = regexp(/[\w#{Special}]*[A-Za-z#{Special}][\w#{Special}]*/).map{|s| s.to_sym }
  String = stringer(%q{"}, %q{"}, "n" => "\n", "t" => "\t")
  List = char('(') >> lazy{Values} << char(')')
  Vector = char('[') >> lazy{Values}.map{|value| [:vector, value] } << char(']')
  Quoted = char("'") >> lazy{Value}.map{|value| [:quote, value] }
  Quasiquoted = char("`") >> lazy{Value}.map{|value| [:quasiquote, value]}
  Commaed = char(",") >> lazy{Value}.map{|value| [:comma_, value]}
  Commented = char(";") >> lazy{Value}.map{|value| nil}
  Value = whitespace.many_ >> alt(Quoted, Quasiquoted, Commaed, Commented, List, Vector, String, Symbol, Number) << whitespace.many_
  Values = Value.many
  Parser = Values << eof

  def self.parse(text)
    denilify Parser.parse(text)
  end
  
  protected
  def self.denilify(list)
    list.reject{|x| x.nil?}.map{|x| x.is_a?(Array) ? denilify(x) : x}
  end
end

class Object; def to_sexp; inspect(); end; end
class Symbol; def to_sexp; id2name(); end; end
class Array;  def to_sexp; "(#{map{|x| x.to_sexp }.join(' ')})"; end; end
class String; def parse_sexp; SExpressionParser.parse(self) ; end; end

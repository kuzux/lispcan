#!/usr/bin/ruby
require 'lisp_parser'

class Cons
  attr_reader :cdr
  attr_accessor :car
  def initialize car, cdr
    @car, @cdr = car, cdr
  end
  
  def to_sexp
    return "(cons #{car.to_sexp} #{cdr.to_sexp})" unless conslist?
    "(#{arrayify.map{|x| x.to_sexp}.join(' ')})"
  end
end

class Env
  def initialize parent=nil, defaults={}
    @parent, @defs = parent, defaults
  end
  
  def define sym, val
    @defs[sym] = val
  end
  
  def defined? sym
    return true if @defs.has_key?(sym)
    return false unless @parent
    @parent.defined? sym
  end
  
  def lookup sym
    return @defs[sym] if @defs.has_key?(sym)
    raise "#{sym} undefined" unless @parent
    @parent.lookup sym
  end
  
  def set sym, val
    if @defs.has_key? sym
      @defs[sym] = val
    elsif @parent.nil?
      raise "#{sym} undefined"
    else
      @parent.set sym, val
    end
  end
  
  def all_keys
    @parent ? @defs.keys+@parent.all_keys : @defs.keys
  end
end

class Lambda
  def initialize env, forms, args, st, *code
    @env, @forms = env,forms
    @args = args.arrayify
    @arity = @args.size
    @arity *= -1 if @args.last.to_s =~ /^\@/
    @code = code
    @stack_trace = st
  end
  
  def call *args
    if @arity > 0
      raise "Expected #{@arity} arguments, got #{args.size}" unless args.size == @arity
    else
      raise "Expected at least #{@arity.abs - 1} arguments, got #{args.size}" unless args.size >= @arity.abs - 1
    end
    
    #@env.define(:"ASD", lambda{|*args| self.call(*args)})
    @env.lookup(:"*interpreter*").push(:"<LAMBDA>") if @st
    
    newenv = Env.new(@env)
    newforms = Env.new(@forms)
    if @arity > 0
      @args.zip(args){|arg,val| newenv.define(arg,val)}
    else
      @args[0..-2].zip(args[0..(@arity.abs-1)]){|arg,val| newenv.define(arg,val)}
      newenv.define(@args.last.to_s[1..-1].to_sym,args[(@arity.abs-1)..-1].consify)
    end
    
    #res = @code.map{|exp| exp.lispeval(newenv,newforms)}.last
    #extremely ugly hack to get better stack depth
    ress = []; len = @code.length; i = 0
    while i < len
      ress << @code[i].lispeval(newenv,newforms)
      i += 1
    end
    res = ress.last
    if res==true||res==false||res==nil
      res = res.to_sym
    end
    @env.lookup(:"*interpreter*").pop if @st
    
    res
  end
  
  def to_sexp
    "(lambda #{@args.consify.to_sexp} #{@code.map{|e| e.to_sexp}.join(" ")})"
  end
  
  def to_proc
    lambda{|*args| self.call *args}
  end
end

## Eval&Apply
class Object
  def lispeval env, forms
    self
  end
end

class Symbol
  def lispeval env, forms
    env.lookup self
  end
end

class TrueClass
  def to_sym
    :t
  end
end

class FalseClass
  def to_sym
    :nil
  end
end

class NilClass
  def to_sym
    :nil
  end
end

class Cons
  def lispeval env, forms
    return forms.lookup(car).call(env, forms, *cdr.arrayify) if forms && forms.defined?(car)
    func = car.lispeval(env,forms)
    args = cdr.arrayify.map{|x| x.lispeval(env,forms)}
    env.lookup(:"*interpreter*").stack_trace << car
    res = func.call(*args)
    env.lookup(:"*interpreter*").stack_trace.pop
    res
  end
end

####Consify&Arrayify
class Object
  def consify; self; end
  def arrayify; self; end
  def conslist?; false; end
end

class Array
  def consify
    map{|x|x.consify}.reverse.inject(:nil){|cdr,car| Cons.new(car,cdr)}
  end
  def arrayify; self; end
end

class Cons
  def arrayify
    #return self unless conslist?
    #[car] + cdr.arrayify
    #Another thing to make stack deeper
    res = []
    curr = self
    while curr != :nil
      res << curr.car
      curr = curr.cdr
    end
    res
  end
  def conslist?
    cdr.conslist?
  end
end

class Symbol
  def arrayify
    self == :nil ? [] : self 
  end
  
  def conslist?
    self == :nil
  end
end

def quasiquote env, forms, exp
  if exp.is_a? Cons
    if exp.car == :unquote
      exp.cdr.car.lispeval(env,forms)
    else
      exp.arrayify.map do |e|
        quasiquote env, forms, e
      end.consify
    end
  else
    exp
  end
end

class Array
  def self.from_cons cns
    new(cns.arrayify)
  end
  
  def to_sexp
    "[#{map{|x| x.to_sexp}.join(' ')}]"
  end
end

class Hash
  def self.from_cons cns
    self[*cns.arrayify]
	end

	def to_sexp
    "{#{map{|k,v| "#{k} #{v}"}.join(" ")}}"
	end
end

DEFAULTS = {}
FORMS = {
  :quote => lambda do |env,forms,exp|
    if exp.is_a?(Cons) && exp.car==:vector
			Cons.new(:"quoted-vector",exp.cdr).lispeval(env,forms)
		elsif exp.is_a?(Cons) && exp.car==:hash
			Cons.new(:"quoted-hash",exp.cdr).lispeval(env,forms)
		else
			exp
		end
	end,
  :quasiquote => lambda {|env,forms,exp| quasiquote(env,forms,exp)},
  :define => lambda {|env,forms,sym,value| env.define(sym,value.lispeval(env,forms))},
  :set_ => lambda{|env,forms,sym,value| env.set(sym.to_sym,value.lispeval(env,forms))},
  :if => lambda{|env,forms,cond,xthen,xelse| (cond.lispeval(env,forms) != :nil) ? xthen.lispeval(env,forms) : xelse.lispeval(env,forms)},
	:try_ => lambda do |env,forms,code,exc,rblock| 
		begin 
		  code.lispeval(env,forms)
		rescue exc.lispeval(env,forms) => e
		  env.define(:"*exception*", e)
			rblock.lispeval(env,forms)
		end
	end,
  :do => lambda{|env,forms,cond,body| body.lispeval(env,forms) while (cond.lispeval(env,forms) != :nil)},
  :lambda => lambda{|env,forms,args,*code| Lambda.new(env,forms,args,true,*code)},
  :defmacro_ => lambda do |env,forms,name,exp|
    func = exp.lispeval(env,forms)
    forms.define(name, lambda{|env2,forms2,*rest| func.call(*rest).lispeval(env2,forms2)})
    name
  end,
  :ruby => lambda {|env,forms,const| Kernel.const_get const },
  :"." => lambda do |env,forms,obj,msg,*params| 
    evald = params.map{|p| p.lispeval(env,forms)}
    proc = nil
    proc = evald.pop if evald.last.is_a? Lambda
    obj.lispeval(env,forms).send(msg,*evald,&proc)
  end,
  :"::" => lambda {|env,forms,mdl,sub| mdl.lispeval(env,forms).const_get sub },
  :eval => lambda{|env,forms,*code| code.map{|c| c.lispeval(env,forms)}.map{|c|c.lispeval(env,forms)}.last}
}

STDLIB = "std.lisp"

class Interpreter
  attr_reader :stack_trace
  def initialize defaults = DEFAULTS, forms = FORMS, stdlib = STDLIB
    @env = Env.new nil, defaults
    @forms = Env.new nil, forms
    @env.define(:"*interpreter*",self)
    @loadpath = [File.join(File.dirname(__FILE__), "std")]
    @stack_trace = [:"TOPLEVEL"]
    load_file stdlib
  end
  
  def add_path(path)
    @loadpath = [path] + @loadpath
  end
  
  def parse(str)
    str.parse_sexp.map do |expr|
      expr.consify
    end.consify
  end
  
  def eval(str)
    str.parse_sexp.map do |expr|
      expr.consify.lispeval(@env,@forms)
    end.last
  end
  
  def repl
    Readline.completion_proc = lambda do |start|
      @env.all_keys.select{|x| x.to_s =~ /^#{Regexp.escape(start)}/} + @forms.all_keys.select{|x| x.to_s =~ /^#{Regexp.escape(start)}/}
    end
    while line = Readline.readline("> ",true)
			begin
        puts self.eval(line).to_sexp
			rescue StandardError => e
				puts "ERROR: #{e}"
				puts @stack_trace.to_sexp
			end
    end
  end
  
  def load_file file
    @loadpath.each do |path|
      begin
        cont = File.read(File.join(path,file))
        eval_file cont
        return
      rescue Errno::ENOENT
        next
      end
    end
    puts "ERROR: The file #{file} could not be found"
  end
  
  def eval_file contents
    contents.parse_sexp.each do |expr|
      expr.consify.lispeval(@env,@forms)
    end
  rescue StandardError => e
    puts "ERROR: #{e}"
    puts @stack_trace.to_sexp
  end
end

if __FILE__ == $0
  int = Interpreter.new
  if ARGV.length == 0
    require 'readline'
    int.repl
  else
    int.add_path File.dirname(ARGV[0])
    int.load_file(ARGV[0])
  end
end

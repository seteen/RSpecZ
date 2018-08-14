module RSpec
  module Core
    module MemoizedHelpers
      module ClassMethods
        class WithContext
          attr_accessor :name, :values, :description, :hint, :focused, :block, :myobject

          def initialize(name, values, block, myobject)
            @name, @values, @block, @myobject = name, values, block, myobject
          end

          def desc(description)
            @description = description
            self
          end

          def hint(text)
            @hint = text
          end

          def focused
            @focused = true
          end

          def so(&block)
            continue_object = self
            continue_object_block = @block
            # TODO: create description from block.source
            if @values.length > 0
              raise RuntimeError.new("Syntax error you cannot set description by 'desc' method when you have multiple values set.") if @values.length > 1 && @description
              @values.each do |value|
                context_text = @hint ? "when #{@name} is #{@hint}(#{value})" : "when #{@name} is #{value}"
                spec = lambda do
                  let(continue_object.name) { value }
                  instance_exec(value, &block)
                end
                if @focused
                  @myobject.fcontext(context_text, &spec)
                else
                  @myobject.context(context_text, &spec)
                end
              end
            else
              spec = lambda do
                if continue_object.name
                  let(continue_object.name) { instance_eval(&continue_object_block) }
                else
                  before { instance_eval(&continue_object_block) }
                end
                instance_exec(&block)
              end

              if @focused
                @myobject.fcontext(@description || "when #{@name} is different", &spec)
              else
                @myobject.context(@description || "when #{@name} is different", &spec)
              end
            end
          end
        end

        def with(name = nil, *values, &block) _with(name, nil, false, values, block); end
        def fwith(name = nil, *values, &block) _with(name, nil, true, values, block); end

        def with_valid(name = nil, *values, &block) _with(name, 'valid', false, values, block); end
        alias_method :with_valids, :with_valid

        def fwith_valid(name = nil, *values, &block) _with(name, 'valid', true, values, block); end
        alias_method :fwith_valids, :fwith_valid

        def with_invalid(name = nil, *values, &block) _with(name, 'invalid', false, values, block); end
        alias_method :with_invalids, :with_invalid

        def fwith_invalid(name = nil, *values, &block) _with(name, 'invalid', true, values, block); end
        alias_method :fwith_invalids, :fwith_invalid

        def with_missing(name = nil, *values, &block) _with(name, 'missing',false, values, block); end
        alias_method :with_missings, :with_missing

        def fwith_missing(name = nil, *values, &block) _with(name, 'missing',true, values, block); end
        alias_method :fwith_missings, :fwith_missing

        def with_nil(*names) _with_nil(names, false); end
        alias_method :with_nils, :with_nil

        def fwith_nil(*names) _with_nil(names, true); end
        alias_method :fwith_nils, :fwith_nil

        private

        def _with(name, hint, focused, values, block)
          with_context = WithContext.new(name, values, block, self)
          with_context.hint(hint) if hint
          with_context.focused if focused
          with_context
        end

        def _with_nil(names, focused)
          raise RuntimeError.new("Argument Error. You should set names.") if names.nil? || names.length == 0

          continue_object = { names: names, focused: focused, myobject: self }

          def continue_object.desc(text)
            raise RuntimeError.new("Error. You cannot use desc with with_nil method.")
          end

          def continue_object.so(&block)
            continue_object = self
            continue_object[:names].each do |name|
              spec = lambda do
                let(name) { nil }
                instance_exec(name, &block)
              end
              if continue_object[:focused]
                self[:myobject].fcontext("When #{name} is nil", &spec)
              else
                self[:myobject].context("When #{name} is nil", &spec)
              end
            end
          end
          continue_object
        end
      end
    end
  end
end